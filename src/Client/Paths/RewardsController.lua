--[[
    Paychecks and Daily Rewards
]]
local RewardsController = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local DataController = require(Paths.Client.DataController)
local RewardsUtil = require(Paths.Shared.Rewards.RewardsUtil)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local ZoneController = require(Paths.Client.ZoneController)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local Promise = require(Paths.Packages.promise)

-- Will prompt the daily streak view as soon as appropriate
function RewardsController.promptDailyRewards()
    Promise.new(function(resolve, _reject, _onCancel)
        while true do
            local canShow = UIController.getStateMachine():GetState() == UIConstants.States.HUD
                and ZoneController.getCurrentZone().ZoneType == ZoneConstants.ZoneType.Room
            if canShow then
                break
            else
                task.wait()
            end
        end
        resolve()
    end):andThen(function()
        UIController.getStateMachine():Push(UIConstants.States.DailyRewards)
    end)
end

function RewardsController.getCurrentDailyStreak()
    return RewardsUtil.getDailyStreakDays(DataController.get(RewardsUtil.getDailyStreakDataAddress()))
end

function RewardsController.getBestDailyStreak()
    return RewardsUtil.getBestDailyStreak(DataController.get(RewardsUtil.getDailyStreakDataAddress()))
end

function RewardsController.getTimeUntilNextDailyStreakReward()
    return RewardsUtil.getTimeUntilNextDailyStreakRenew(DataController.get(RewardsUtil.getDailyStreakDataAddress()))
end

-- DailyStreakUpdated
do
    DataController.Updated:Connect(function(event: string, _newValue: any)
        if event == "DailyStreakUpdated" then
            RewardsController.promptDailyRewards()
        end
    end)
end

return RewardsController
