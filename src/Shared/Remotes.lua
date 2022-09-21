local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Remotes = {}

local Promise = require(script.Parent.Promise)

local eventHandlers = {}
local functionHandlers = {}

local isStudio = RunService:IsStudio()
local isServer = RunService:IsServer()

local communication, functionFolder, eventFolder

-- Unessecary, i just like one liners
local function instance(class, name, parent)
    local creating = Instance.new(class)
    creating.Name = name
    creating.Parent = parent

    return creating
end

local function waitForChild(parent, awaiting)
    local returning = parent:FindFirstChild(awaiting)

    if not returning then
        Promise.fromEvent(parent.ChildAdded, function(added)
            if added.Name == awaiting then
                returning = added
                return true
            end
            return false
        end):await()
    end

    return returning
end

local function getFunctionHandler(name)
    assert(typeof(name) == "string", "Remote name is not a string -> " .. name)

    local handler = functionHandlers[name]
    if handler then
        return handler
    end

    handler = {}
    handler.Remote = isServer and instance("RemoteFunction", tostring(name), functionFolder) or waitForChild(functionFolder, name)
    if isStudio and not isServer then -- anti hack
        handler.Remote.Name = "NO WAY JOSE"
    end

    local set = false
    function handler.registerCallback(callback)
        if set then
            error(string.format("Attempt to overwrite callback: %s", name))
        end

        set = true
        handler.Remote[isServer and "OnServerInvoke" or "OnClientInvoke"] = callback
    end

    functionHandlers[name] = handler
    return handler
end

local function getEventHandler(name)
    assert(typeof(name) == "string", "Remote name is not a string -> " .. name)

    local handler = eventHandlers[name]
    if handler then
        return handler
    end

    handler = {}
    handler.Remote = isServer and instance("RemoteEvent", name, eventFolder) or waitForChild(eventFolder, name)
    if isStudio and not isServer then -- anti hack
        handler.Remote.Name = "YOUR MOM"
    end

    local callbacks = {}
    local history = {}

    function handler.registerCallback(callback, temp)
        if not temp then
            for _, fire in ipairs(history) do
                task.spawn(callback, table.unpack(fire))
            end
        end

        local i = #callbacks + 1
        callbacks[i] = callback

        return function()
            table.remove(callbacks, i)
        end
    end

    handler.Remote[isServer and "OnServerEvent" or "OnClientEvent"]:Connect(function(...)
        table.insert(history, table.pack(...))
        for _, callback in ipairs(callbacks) do
            task.spawn(callback, ...)
        end
    end)

    eventHandlers[name] = handler
    return handler
end

-- Bindings, pass a dictionary of remotes to create / connect to
function Remotes.bindFunctions(callbacks)
    for name, callback in pairs(callbacks) do
        assert(callback, name)
        assert(typeof(callback) == "function", name)

        task.spawn(function()
            local handler = getFunctionHandler(name)
            handler.registerCallback(callback)
        end)
    end
end

function Remotes.bindEvents(callbacks)
    for name, callback in pairs(callbacks) do
        assert(callback, name)
        assert(typeof(callback) == "function", name)

        task.spawn(function()
            local handler = getEventHandler(name)
            handler.registerCallback(callback)
        end)
    end
end

function Remotes.bindEventTemp(name, callback) -- SYNCROHOUNOUS
    local handler = getEventHandler(name)
    local disconnect = handler.registerCallback(callback, true)

    local returning = {}
    returning.Disconnect = disconnect
    returning.Destroy = disconnect

    return returning
end

if isServer then
    communication = instance("Folder", "Communication", ReplicatedStorage)
    functionFolder = instance("Folder", "Functions", communication)
    eventFolder = instance("Folder", "Events", communication)

    function Remotes.invokeClient(client, name, ...)
        assert(client.Parent == Players, "Can't fire to non-existent player " .. client.Name)

        local handler = getFunctionHandler(name)
        local remote = assert(handler.Remote, name)

        return remote:InvokeClient(client, ...)
    end

    function Remotes.invokeClients(clients, ...)
        local returning = {}
        for _, player in ipairs(clients) do
            returning[player] = table.pack(Remotes.invokeClient(player, ...))
        end
        return returning
    end

    function Remotes.invokeAllClients(...)
        return Remotes.invokeClients(Players:GetPlayers(), ...)
    end

    function Remotes.fireClient(client, name, ...)
        task.spawn(function(...)
            assert(client.Parent == Players, "Can't fire to non-existent player " .. client.Name)

            local handler = getEventHandler(name)
            local remote = assert(handler.Remote, name)
            remote:FireClient(client, ...)
        end, ...)
    end

    function Remotes.fireClients(clients, ...)
        for _, player in ipairs(clients) do
            Remotes.fireClient(player, ...)
        end
    end

    function Remotes.fireAllClients(...)
        Remotes.fireClients(Players:GetPlayers(), ...)
    end

    function Remotes.fireAllOtherClients(ignore, ...)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= ignore then
                Remotes.fireClient(player, ...)
            end
        end
    end
else
    communication = ReplicatedStorage:WaitForChild("Communication")
    functionFolder = communication:WaitForChild("Functions")
    eventFolder = communication:WaitForChild("Events")

    function Remotes.fireServer(name, ...)
        task.spawn(function(...)
            local handler = getEventHandler(name)
            local remote = assert(handler.Remote, name)

            remote:FireServer(...)
        end, ...)
    end

    function Remotes.invokeServer(name, ...)
        local handler = getFunctionHandler(name)
        local remote = assert(handler.Remote, name)

        return remote:InvokeServer(...)
    end
end

return Remotes
