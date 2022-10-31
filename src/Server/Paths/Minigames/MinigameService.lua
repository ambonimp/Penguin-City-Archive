local MinigameService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local MinigameQueue = require(Paths.Server.Minigames.MinigameQueue)
local MinigameSession = require(Paths.Server.Minigames.MinigameSession)

local queues: { [string]: typeof(MinigameQueue.new("")) } = {}
local sessions: { [string]: { [string]: typeof(MinigameSession.new("", "", {})) } } = {}
local sessionIdCounter = 0

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function createSession(minigame: string, participants: { Player })
    local id = tostring(sessionIdCounter)
    sessionIdCounter += 1

    local session = require(Paths.Server.Minigames[minigame][minigame .. "Session"]).new(participants)
    sessions[minigame][id] = session
    session:GetMaid():GiveTask(function()
        sessions[minigame][id] = nil
    end)
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function MinigameService.requestToPlayerMultiplayer(player: Player, minigame: string, solo: boolean)
    -- RETURN: Minigame isn't valid
    if not MinigameConstants.MultiplayerMinigames[minigame] then
        return
    end

    -- RETURN: Player is already in a minigame
    if ZoneService.getPlayerMinigame(player) then
        return
    end

    if solo then
        createSession(minigame, { player })
    else
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
    end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
for minigame in pairs(MinigameConstants) do
    sessions[minigame] = {}
end
return MinigameService
