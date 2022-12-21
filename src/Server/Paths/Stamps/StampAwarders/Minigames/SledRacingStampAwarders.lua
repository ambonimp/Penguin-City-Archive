local SledRacingStampAwarders = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local StampService = require(Paths.Server.Stamps.StampService)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local MinigameSession = require(Paths.Server.Minigames.MinigameSession)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local SledRaceSession = require(Paths.Server.Minigames.SledRace.SledRaceSession)

local sledRaceWinsTieredStamp = StampUtil.getStampFromId("minigame_sledrace_wins")
local hitObstacleStamp = StampUtil.getStampFromId("minigame_sledrace_obstacle")
local useSpeedBoostStamp = StampUtil.getStampFromId("minigame_sledrace_boost")
local winStreak5Stamp = StampUtil.getStampFromId("minigame_sledrace_winstreak5")

-- sledRaceWinsTieredStampm,winStreak5Stamp
MinigameSession.MinigameFinished:Connect(
    function(minigameSession: MinigameSession.MinigameSession, sortedScores: MinigameConstants.SortedScores)
        -- RETURN: Not sled racing
        if not (minigameSession:GetMinigameName() == MinigameConstants.Minigames.SledRace) then
            return
        end

        -- Winning
        local winningScore = sortedScores[1]
        if winningScore then
            -- Wins
            StampService.incrementStamp(winningScore.Player, sledRaceWinsTieredStamp.Id, 1)

            -- Streak
            if winningScore.ConsecutiveWins and winningScore.ConsecutiveWins >= 5 then
                StampService.addStamp(winningScore.Player, winStreak5Stamp.Id)
            end
        end
    end
)

SledRaceSession.CollectableCollected:Connect(function(_session: SledRaceSession.SledRaceSession, player: Player, collectableType: string)
    if collectableType == "Obstacle" then
        StampService.addStamp(player, hitObstacleStamp.Id)
    end

    if collectableType == "Boost" then
        StampService.addStamp(player, useSpeedBoostStamp.Id)
    end
end)

return SledRacingStampAwarders
