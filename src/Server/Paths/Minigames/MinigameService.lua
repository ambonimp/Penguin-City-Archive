local MinigameService = {}

local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local MinigameQueue = require(Paths.Server.Minigames.MinigameQueue)
local MinigameSession = require(Paths.Server.Minigames.MinigameSession)
local MinigameUtil = require(Paths.Shared.Minigames.MinigameUtil)
local Remotes = require(Paths.Shared.Remotes)

local sessionClasses = {}

local activeQueues: { [string]: { typeof(MinigameQueue.new("")) } } = {}
local activeSessions: { [string]: { [string]: typeof(MinigameSession.new("", "", {}, true)) } } = {}
local sessionIdCounter = 0

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function createSession(minigame: string, participants: { Player }, isMultiplayer: boolean, queueStation: Model?)
    local id = tostring(sessionIdCounter)
    sessionIdCounter += 1

    local session = sessionClasses[minigame].new(minigame, id, participants, isMultiplayer, queueStation)
    activeSessions[minigame][id] = session
    session:GetJanitor():Add(function()
        activeSessions[minigame][id] = nil
    end)
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function MinigameService.requestToPlay(player: Player, minigame: string, multiplayer: boolean, queueStation: Model?)
    -- RETURN: Player is already in a minigame
    if ZoneService.getPlayerMinigame(player) then
        return
    end

    -- RETURN: Player is already in a queue
    if multiplayer then
        for _, queues in pairs(activeQueues) do
            for _, queue in pairs(queues) do
                if queue:IsParticipant(player) then
                    return
                end
            end
        end
    end

    local sessionConfig = MinigameUtil.getsessionConfig(minigame)
    if multiplayer then
        -- RETURN: No multiplayer support
        if not sessionConfig.Multiplayer then
            warn(("%s minigame doesn't support multiplayer play"):format(minigame))
            return
        end

        -- Search for existing session
        for _, session in pairs(activeSessions[minigame]) do
            if session:IsAcceptingNewParticipants() then
                session:AddParticipant(player)
                Remotes.fireClient(player, "MinigameQueueExited")
                return
            end
        end

        -- Couldn't find any, look for queues
        local queueJoining
        local potentialQueues = activeQueues[minigame]

        if queueStation then
            for _, queue in pairs(potentialQueues) do
                if queue:GetStation() == queueStation then
                    queueJoining = queue
                end
            end
        else
            queueJoining = potentialQueues[1]
        end

        if queueJoining then
            queueJoining:AddParticipant(player)
        else
            queueJoining = MinigameQueue.new(minigame, queueStation)
            queueJoining:GetJanitor():Add(function()
                task.defer(function()
                    table.remove(potentialQueues, table.find(potentialQueues, queueJoining))
                    createSession(minigame, queueJoining:GetParticipants(), true, queueStation)
                end)
            end)

            table.insert(potentialQueues, queueJoining)
            queueJoining:AddParticipant(player)
        end
    else
        -- RETURN: No single player support
        if not sessionConfig.SinglePlayer then
            warn(("%s minigame doesn't support single player play"):format(minigame))
            return
        end

        createSession(minigame, { player }, false)
    end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
Remotes.bindFunctions({
    MinigamePlayRequested = MinigameService.requestToPlay,
})

for minigame in pairs(MinigameConstants.Minigames) do
    activeSessions[minigame] = {}
    activeQueues[minigame] = {}
    sessionClasses[minigame] = require(Paths.Server.Minigames[minigame][minigame .. "Session"])
end

for _, prompt: BasePart in pairs(CollectionService:GetTagged("MinigamePrompt")) do
    prompt.Transparency = 1
    prompt.CanCollide = false
    prompt.Anchored = true
    prompt.CastShadow = false
end

Remotes.declareEvent("MinigameJoined")
Remotes.declareEvent("MinigameExited")
Remotes.declareEvent("MinigameParticipantAdded")
Remotes.declareEvent("MinigameParticipantRemoved")
Remotes.declareEvent("MinigameStateChanged")

return MinigameService
