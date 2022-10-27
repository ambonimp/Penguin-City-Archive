--[[
    Paychecks and Daily Rewards
]]
local RewardsService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local DataService = require(Paths.Server.Data.DataService)
local RewardsUtil = require(Paths.Shared.Rewards.RewardsUtil)
local PlayerService = require(Paths.Server.PlayerService)

--[[
    Updates a players daily streak, calculating if their streak should be increased, expired etc..
    Informs the client.
]]
function RewardsService.updateDailyStreak(player: Player)
    local dailyStreakData = DataService.get(player, RewardsUtil.getDailyStreakDataAddress())
    local updatedDailyStreakData = RewardsUtil.getUpdatedDailyStreak(dailyStreakData)

    -- Streak updated!
    local hasStreakNumberMismatch = RewardsUtil.getDailyStreakNumber(dailyStreakData)
        ~= RewardsUtil.getDailyStreakNumber(updatedDailyStreakData)
    local hasDaysMismatch = RewardsUtil.getDailyStreakDays(dailyStreakData) ~= RewardsUtil.getDailyStreakDays(updatedDailyStreakData)
    if hasStreakNumberMismatch or hasDaysMismatch then
        DataService.set(player, RewardsUtil.getDailyStreakDataAddress(), updatedDailyStreakData, "DailyStreakUpdated")
    end
end

function RewardsService.addDailyStreak(player: Player, days: number)
    RewardsService.updateDailyStreak(player)
    for _ = 1, days do
        RewardsUtil.setDailyStreakRenewTime(DataService.get(player, RewardsUtil.getDailyStreakDataAddress()), 0)
        RewardsService.updateDailyStreak(player)
    end
end

function RewardsService.loadPlayer(player: Player)
    -- Daily Streak
    RewardsService.updateDailyStreak(player)
    PlayerService.getPlayerMaid(player):GiveTask(function()
        RewardsService.updateDailyStreak(player)
    end)
end

return RewardsService
