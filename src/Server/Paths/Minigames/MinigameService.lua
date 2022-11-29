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

local activeQueues: { [string]: typeof(MinigameQueue.new("")) } = {}
local activeSessions: { [string]: { [string]: typeof(MinigameSession.new("", "", {}, true)) } } = {}
local sessionIdCounter = 0

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function createSession(minigame: string, participants: { Player }, isMultiplayer: boolean, queueStation: Model?)
    local id = tostring(sessionIdCounter)
    sessionIdCounter += 1

    local session = sessionClasses[minigame].new(id, participants, isMultiplayer, queueStation)
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
        for _, queue in pairs(activeQueues) do
            if queue:IsParticipant(player) then
                return
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
        local potentialactiveSessions = {}
        for _, sessions in pairs(activeSessions) do
            for _, session in pairs(sessions) do
                if session:IsAcceptingNewParticipants() then
                    table.insert(potentialactiveSessions, session)
                end
            end
        end

        if #potentialactiveSessions == 0 then
            local queue = activeQueues[minigame]
            if queue then
                queue:AddParticipant(player)
            else
                queue = MinigameQueue.new(minigame, queueStation)
                queue:GetJanitor():Add(function()
                    activeQueues[minigame] = nil
                    createSession(minigame, queue:GetParticipants(), true, queueStation)
                end)

                activeQueues[minigame] = queue
                queue:AddParticipant(player)
            end
        else
            -- TODO: Prioritize minigames the player has friends in
            local session = potentialactiveSessions[1]
            session:AddParticipant(player)
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
