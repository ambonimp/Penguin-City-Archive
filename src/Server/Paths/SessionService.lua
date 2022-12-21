--[[
    Keeps our `Sessions` populated with beaucoup de information; used for our "Session Summary" telemetry
]]
local SessionService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Session = require(Paths.Shared.Session)
local PlayerService = require(Paths.Server.PlayerService)
local MinigameSession = require(Paths.Server.Minigames.MinigameSession)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local DataService = require(Paths.Server.Data.DataService)

local DATA_ADDRESS_TOTAL_PLAY_SESSIONS = "Sessions.TotalSessions"

local sessionByPlayer: { [Player]: typeof(Session.new(game.Players:GetPlayers()[1])) } = {}

function SessionService.Start()
    -- Populate minigame time sessions
    do
        MinigameSession.MinigameFinished:Connect(
            function(minigameSession: MinigameSession.MinigameSession, sortedScores: MinigameConstants.SortedScores)
                local minigameTimeSeconds = minigameSession:GetSessionTime()
                for _, scoreInfo in pairs(sortedScores) do
                    local session = SessionService.getSession(scoreInfo.Player)
                    if session then
                        session:AddMinigameTimeSeconds(minigameTimeSeconds)
                    end
                end
            end
        )
    end

    -- Populate ZoneTeleports
    do
        ZoneService.ZoneChanged:Connect(
            function(player: Player, fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone, teleportData: ZoneConstants.TeleportData)
                local session = SessionService.getSession(player)
                if session then
                    session:ReportZoneTeleport(fromZone, toZone, teleportData)
                end
            end
        )
    end
end

function SessionService.loadPlayer(player: Player)
    -- Load `Session` Object
    sessionByPlayer[player] = Session.new(player)
    PlayerService.getPlayerMaid(player):GiveTask(function()
        sessionByPlayer[player] = nil
    end)

    -- Add to total play sessions
    DataService.increment(player, DATA_ADDRESS_TOTAL_PLAY_SESSIONS, 1)
end

function SessionService.getSession(player: Player)
    return sessionByPlayer[player]
end

function SessionService.getTotalPlaySessions(player: Player): number
    return DataService.get(player, DATA_ADDRESS_TOTAL_PLAY_SESSIONS) or 0
end

return SessionService
