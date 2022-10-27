--[[
    Paychecks and Daily Rewards
]]
local RewardsService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local DataService = require(Paths.Server.Data.DataService)
local RewardsUtil = require(Paths.Shared.Utils.RewardsUtil)

function RewardsService.updateDailyStreak(player: Player)
    local dailyStreakData = DataService.get(player, RewardsUtil.getDailyStreakDataAddress())
    local updatedDailyStreakData = RewardsUtil.getUpdatedDailyStreak(dailyStreakData)

    -- Streak updated!
    local hasStreakNumberMismatch = RewardsUtil.getDailyStreakNumber(dailyStreakData)
        ~= RewardsUtil.getDailyStreakNumber(updatedDailyStreakData)
    local hasDaysMismatch = RewardsUtil.getDailyStreakDays(dailyStreakData) ~= RewardsUtil.getDailyStreakNumber(updatedDailyStreakData)
    if hasStreakNumberMismatch or hasDaysMismatch then
        DataService.set(player, RewardsUtil.getDailyStreakDataAddress(), updatedDailyStreakData, "DailyStreakUpdated")
    end
end

function RewardsService.loadPlayer(player: Player)
    RewardsService.updateDailyStreak(player)
end

return RewardsService
