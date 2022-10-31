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
local Assume = require(Paths.Shared.Assume)
local Remotes = require(Paths.Shared.Remotes)
local RewardsConstants = require(Paths.Shared.Rewards.RewardsConstants)
local Maid = require(Paths.Packages.maid)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local CurrencyController = require(Paths.Client.CurrencyController)
local Signal = require(Paths.Shared.Signal)
local DescendantLooper = require(Paths.Shared.DescendantLooper)
local DailyRewardsScreen = require(Paths.Client.UI.Screens.DailyRewards.DailyRewardsScreen)

local ATTRIBUTE_DAILY_REWARDS_VIEWPORT = "DailyRewardsViewport"

RewardsController.DailyStreakUpdated = Signal.new()

-------------------------------------------------------------------------------
-- DailyStreak
-------------------------------------------------------------------------------

-- Will prompt the daily streak view as soon as appropriate
function RewardsController.promptDailyRewards()
    -- RETURN: Already open
    if UIController.getStateMachine():GetState() == UIConstants.States.DailyRewards then
        return
    end

    -- Start opening logic
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
        UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.DailyRewards)
        UIController.getStateMachine():Push(UIConstants.States.DailyRewards)
    end)
end

function RewardsController.claimDailyStreakRequest()
    -- RETURN: Nothing to claim!
    local unclaimedDays = RewardsController.getUnclaimedDailyStreakDays()
    if TableUtil.isEmpty(unclaimedDays) then
        warn("Nothing to claim")
        return
    end

    -- Convert to non-mixed
    local toServerUnclaimedDays = TableUtil.mapKeys(unclaimedDays, function(key)
        return tostring(key)
    end)

    local rewardMaid = Maid.new()

    local claimAssume = Assume.new(function()
        return Remotes.invokeServer("ClaimDailyStreakRequest", toServerUnclaimedDays)
    end)
    claimAssume:Check(function(wasSuccess: boolean)
        return wasSuccess and true or false
    end)
    claimAssume
        :Run(function()
            task.spawn(function()
                local doReward = true
                for dayNum, amount in pairs(unclaimedDays) do
                    local reward = RewardsUtil.getDailyStreakReward(dayNum)
                    rewardMaid:GiveTask(RewardsController.giveReward(reward, amount))

                    if not doReward then
                        break
                    end
                end

                rewardMaid:GiveTask(function()
                    doReward = false
                end)
            end)
        end)
        :Else(function()
            rewardMaid:Destroy()
        end)

    return claimAssume
end

-- Returns a maid that will cleanup + revert the application of this reward
function RewardsController.giveReward(reward: RewardsConstants.DailyStreakReward, amount: number)
    if reward.Coins then
        local coins = reward.Coins * amount

        CurrencyController.addCoins(coins)
        return Maid.new(function()
            CurrencyController.addCoins(-coins)
        end)
    end

    if reward.Gift then
        warn("todo give gift reward", reward, amount)
        return Maid.new(function()
            warn("revoke gift reward", reward, amount)
        end)
    end

    warn("Don't know how to give reward", reward)
end

local function getDailyStreakData()
    return DataController.get(RewardsUtil.getDailyStreakDataAddress())
end

function RewardsController.getCurrentDailyStreak()
    return RewardsUtil.getDailyStreakDays(getDailyStreakData())
end

function RewardsController.getBestDailyStreak()
    return RewardsUtil.getBestDailyStreak(getDailyStreakData())
end

function RewardsController.getTimeUntilNextDailyStreakReward()
    return RewardsUtil.getTimeUntilNextDailyStreakRenew(getDailyStreakData())
end

function RewardsController.getUnclaimedDailyStreakDays()
    return RewardsUtil.getUnclaimedDailyStreakDays(getDailyStreakData())
end

-- DailyStreakUpdated
do
    DataController.Updated:Connect(function(event: string, _newValue: any)
        if event == "DailyStreakUpdated" then
            RewardsController.DailyStreakUpdated:Fire()
            RewardsController.promptDailyRewards()
        end
    end)
end

-- DailyRewardsViewports
DescendantLooper.workspace(function(instance)
    return instance:GetAttribute(ATTRIBUTE_DAILY_REWARDS_VIEWPORT) and true or false
end, function(instance)
    local faceString = instance:GetAttribute(ATTRIBUTE_DAILY_REWARDS_VIEWPORT)
    local face = Enum.NormalId[faceString]
    DailyRewardsScreen.attachToPart(instance, face)
end)

return RewardsController
