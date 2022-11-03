local MinigameService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local MinigameQueue = require(Paths.Server.Minigames.MinigameQueue)
local MinigameSession = require(Paths.Server.Minigames.MinigameSession)
local MinigameUtil = require(Paths.Shared.Minigames.MinigameUtil)
local Remotes = require(Paths.Shared.Remotes)

local queues: { [string]: typeof(MinigameQueue.new("")) } = {}
local sessions: { [string]: { [string]: typeof(MinigameSession.new("", "", {})) } } = {}
local sessionIdCounter = 0

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function createSession(minigame: string, participants: { Player })
    local id = tostring(sessionIdCounter)
    sessionIdCounter += 1

    local session = require(Paths.Server.Minigames[minigame][minigame .. "Session"]).new(id, participants)
    sessions[minigame][id] = session
    session:GetMaid():GiveTask(function()
        sessions[minigame][id] = nil
    end)
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function MinigameService.requestToPlay(player: Player, minigame: string, multiplayer: boolean)
    -- RETURN: Player is already in a minigame
    if ZoneService.getPlayerMinigame(player) then
        return
    end

    local sessionConfigs = MinigameUtil.getSessionConfigs(minigame)

    if multiplayer then
        -- RETURN: No multiplayer support
        if not sessionConfigs.Multiplayer then
            warn(("% minigame doesn't support multiplayer play"):format(minigame))
            return
        end

        -- Search for existing session
        local potentialSessions = {}
        for _, session in pairs(queues) do
            if session:IsAcceptingNewParticipants() then
                table.insert(potentialSessions, session)
            end
        end

        if #potentialSessions == 0 then
            local queue = queues[minigame]
            if queue then
                queue:AddParticipant(player)
            else
                queue = MinigameQueue.new(minigame)
                queue:GiveTask(function()
                    queues[minigame] = nil
                    createSession(minigame, queues:GetParticipants())
                end)

                queues[minigame] = queue
            end
        else
            -- TODO: Prioritize minigames the player has friends in
            local session = potentialSessions[1]
            session:AddParticipant(player)
        end
    else
        -- RETURN: No single player support
        if not sessionConfigs.SinglePlayer then
            warn(("% minigame doesn't support single player play"):format(minigame))
            return
        end
        createSession(minigame, { player })
    end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
for minigame in pairs(MinigameConstants.Minigames) do
    sessions[minigame] = {}
end

do
    Remotes.declareEvent("MinigameJoined")
    Remotes.declareEvent("MinigameExited")
    Remotes.declareEvent("MinigameParticipantAdded")
    Remotes.declareEvent("MinigameParticipantRemoved")
    Remotes.declareEvent("MinigameStateChanged")
end

return MinigameService
