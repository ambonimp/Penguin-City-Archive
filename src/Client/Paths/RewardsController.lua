--[[
    Paychecks and Daily Rewards
]]
local RewardsController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local DataController = require(Paths.Client.DataController)
local RewardsUtil = require(Paths.Shared.Utils.RewardsUtil)

function RewardsController.dailyStreakUpdated(days: number)
    warn("DAYS:", days)
end

-- DailyStreakUpdated
do
    DataController.Updated:Connect(function(event: string, newValue: any)
        if event == "DailyStreakUpdated" then
            RewardsController.dailyStreakUpdated(RewardsUtil.getDailyStreakDays(newValue))
        end
    end)
end

return RewardsController
