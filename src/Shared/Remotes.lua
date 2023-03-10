--[[
    Client/Server Networking
]]
local Remotes = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local InstanceUtil = require(ReplicatedStorage.Shared.Utils.InstanceUtil)

type FunctionCallback = (...any) -> (...any)
type FunctionHandler = {
    Remote: RemoteFunction,
    registerCallback: (callback: FunctionCallback) -> (),
}
type EventCallback = (...any) -> (nil)
type EventHandler = {
    Remote: RemoteEvent,
    registerCallback: (callback: EventCallback, dontCascade: boolean?) -> (() -> nil),
}

local RATE_LIMITS_PER_SECOND = 20

local eventHandlers: { [string]: EventHandler } = {}
local functionHandlers: { [string]: FunctionHandler } = {}
local rateLimitsByPlayer: { [Player]: number } = {}
local communicationFolder: Folder, functionFolder: Folder, eventFolder: Folder

local function addRateLimit(player: Player)
    rateLimitsByPlayer[player] = rateLimitsByPlayer[player] + 1
    task.delay(1, function()
        if rateLimitsByPlayer[player] then
            rateLimitsByPlayer[player] = rateLimitsByPlayer[player] - 1
        end
    end)
end

local function getRateLimit(player: Player)
    return rateLimitsByPlayer[player]
end

local function isRateLimited(player: Player)
    return rateLimitsByPlayer[player] > RATE_LIMITS_PER_SECOND
end

local function getFunctionHandler(name: string): FunctionHandler
    assert(typeof(name) == "string", "Remote name is not a string -> " .. name)

    local handler = functionHandlers[name]
    if handler then
        return handler
    end

    handler = {}
    handler.Remote = RunService:IsServer() and InstanceUtil.new("RemoteFunction", tostring(name), functionFolder)
        or functionFolder:WaitForChild(name)
    if not RunService:IsStudio() and not RunService:IsServer() then -- anti hack
        handler.Remote.Name = "RemoteFunction"
    end

    local callbackIsSet = false
    function handler.registerCallback(callback: FunctionCallback)
        if callbackIsSet then
            error(string.format("Attempt to overwrite callback: %s", name))
        end

        callbackIsSet = true

        if RunService:IsServer() then
            handler.Remote.OnServerInvoke = function(player: Player, ...)
                addRateLimit(player)

                if not isRateLimited(player) then
                    return callback(player, ...)
                elseif getRateLimit(player) == RATE_LIMITS_PER_SECOND + 1 then
                    warn("Starting to rate limit", player)
                end
            end
        elseif RunService:IsClient() then
            handler.Remote.OnClientInvoke = function(...)
                callback(...)
            end
        end
    end

    functionHandlers[name] = handler
    return handler
end

local function getEventHandler(name: string): EventHandler
    assert(typeof(name) == "string", "Remote name is not a string -> " .. name)

    local handler = eventHandlers[name]
    if handler then
        return handler
    end

    handler = {}
    handler.Remote = RunService:IsServer() and InstanceUtil.new("RemoteEvent", name, eventFolder) or eventFolder:WaitForChild(name)
    if not RunService:IsStudio() and not RunService:IsServer() then -- anti hack
        handler.Remote.Name = "RemoteEvent"
    end

    local callbacks: { EventCallback } = {}
    local history = {}

    --[[ 
        - dontCascade: Whenever an event is fired, we record it. If we connect a callback after the event has been fired, it will call that
        callback with the previous firings. This will *not* be the case if `dontCascade=true`.
        - Returns a function that will internally remove the passed callback when invoked
    --]]
    function handler.registerCallback(callback: EventCallback, dontCascade: boolean?)
        dontCascade = dontCascade and true or false

        if not dontCascade then
            for _, fire in ipairs(history) do
                task.spawn(callback, table.unpack(fire))
            end
        end

        table.insert(callbacks, callback)

        return function()
            local index = table.find(callbacks, callback)
            if index then
                table.remove(callbacks, index)
            end
        end
    end

    if RunService:IsServer() then
        handler.Remote.OnServerEvent:Connect(function(player: Player, ...)
            addRateLimit(player)

            if not isRateLimited(player) then
                table.insert(history, table.pack(player, ...))
                for _, callback in ipairs(callbacks) do
                    task.spawn(callback, player, ...)
                end
            elseif getRateLimit(player) == RATE_LIMITS_PER_SECOND + 1 then
                warn("Starting to rate limit", player)
            end
        end)
    elseif RunService:IsClient() then
        handler.Remote.OnClientEvent:Connect(function(...)
            table.insert(history, table.pack(...))
            for _, callback in ipairs(callbacks) do
                task.spawn(callback, ...)
            end
        end)
    end

    eventHandlers[name] = handler
    return handler
end

function Remotes.bindFunctions(callbacks: { [string]: FunctionCallback })
    for name, callback in pairs(callbacks) do
        assert(callback and typeof(callback) == "function", ("%s has no valid callback function assigned"):format(name))

        task.spawn(function()
            local handler = getFunctionHandler(name)
            handler.registerCallback(callback)
        end)
    end
end

function Remotes.bindEvents(callbacks: { [string]: EventCallback })
    for name, callback in pairs(callbacks) do
        assert(callback and typeof(callback) == "function", ("%s has no valid callback function assigned"):format(name))

        task.spawn(function()
            local handler = getEventHandler(name)
            handler.registerCallback(callback)
        end)
    end
end

--[[
    Returns a function that when invoked will remove the passed callback from existence
    WARNING: This function yields if events aren't declared before hand
]]
function Remotes.bindEventTemp(name: string, callback: EventCallback)
    local handler = getEventHandler(name)
    return handler.registerCallback(callback, true)
end

-- Setup
if RunService:IsServer() then
    communicationFolder = InstanceUtil.new("Folder", "Communication", ReplicatedStorage)
    functionFolder = InstanceUtil.new("Folder", "Functions", communicationFolder)
    eventFolder = InstanceUtil.new("Folder", "Events", communicationFolder)

    function Remotes.fireClient(client: Player, eventName: string, ...: any)
        task.spawn(function(...)
            if not client.Parent == Players then
                error(("Can't fire to non-existent player %q"):format(tostring(client.Name)))
            end

            getEventHandler(eventName).Remote:FireClient(client, ...)
        end, ...)
    end

    function Remotes.fireClients(clients: { Player }, eventName: string, ...: any)
        for _, player in ipairs(clients) do
            Remotes.fireClient(player, eventName, ...)
        end
    end

    function Remotes.fireAllClients(eventName: string, ...: any)
        Remotes.fireClients(Players:GetPlayers(), eventName, ...)
    end

    function Remotes.fireAllOtherClients(ignoreClient: Player, eventName: string, ...: any)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= ignoreClient then
                Remotes.fireClient(player, eventName, ...)
            end
        end
    end

    -- Used to create an event that clients can immediately connect to, even if the Server will not fire it immediately
    function Remotes.declareEvent(eventName: string)
        getEventHandler(eventName)
    end

    -- Rate Limit Init/ Cleanup
    Players.PlayerAdded:Connect(function(player)
        rateLimitsByPlayer[player] = 0
    end)
    Players.PlayerRemoving:Connect(function(player)
        rateLimitsByPlayer[player] = nil
    end)
else
    communicationFolder = ReplicatedStorage:WaitForChild("Communication")
    functionFolder = communicationFolder:WaitForChild("Functions")
    eventFolder = communicationFolder:WaitForChild("Events")

    function Remotes.fireServer(eventName: string, ...: any)
        task.spawn(function(...)
            getEventHandler(eventName).Remote:FireServer(...)
        end, ...)
    end

    function Remotes.invokeServer(functionName: string, ...: any)
        return getFunctionHandler(functionName).Remote:InvokeServer(...)
    end
end

return Remotes
