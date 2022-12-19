local SledRacingStampAwarders = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local StampService = require(Paths.Server.Stamps.StampService)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local MinigameSession = require(Paths.Server.Minigames.MinigameSession)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)

local sledRaceWinsTieredStamp = StampUtil.getStampFromId("minigame_sledrace_wins")
local hitObstacleStamp = StampUtil.getStampFromId("minigame_sledrace_obstacle") --todo
local useSpeedBoostStamp = StampUtil.getStampFromId("minigame_sledrace_boost") --todo
local winStreak5Stamp = StampUtil.getStampFromId("minigame_sledrace_winstreak5") --todo

-- minigame_sledrace_wins
MinigameSession.MinigameFinished:Connect(
    function(minigameSession: MinigameSession.MinigameSession, sortedScores: MinigameConstants.SortedScores)
        -- RETURN: Not sled racing
        if not (minigameSession:GetMinigameName() == MinigameConstants.Minigames.SledRace) then
            return
        end

        local winnerPlayer = sortedScores[1] and sortedScores[1].Player
        if winnerPlayer then
            StampService.incrementStamp(winnerPlayer, sledRaceWinsTieredStamp.Id, 1)
        end
    end
)

return SledRacingStampAwarders
