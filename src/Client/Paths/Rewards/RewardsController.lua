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
local Effects = require(Paths.Shared.Effects)
local ProductController = require(Paths.Client.ProductController)

local ATTRIBUTE_DAILY_REWARDS_VIEWPORT = "DailyRewardsViewport"
local COIN_EFFECT_DURATION = 3

RewardsController.DailyStreakUpdated = Signal.new()

-------------------------------------------------------------------------------
-- DailyStreak
-------------------------------------------------------------------------------

-- Will prompt the daily streak view as soon as appropriate
function RewardsController.promptDailyRewards(needsUnclaimedDays: boolean?)
    -- RETURN: Already open
    if UIController.getStateMachine():GetState() == UIConstants.States.DailyRewards then
        return
    end

    -- RETURN: Needs unclaimed days and there are none
    if needsUnclaimedDays and TableUtil.isEmpty(RewardsController.getUnclaimedDailyStreakDays()) == true then
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
                    if reward.Gift then
                        reward = RewardsUtil.getDailyStreakGift(
                            dayNum,
                            RewardsController.getDailyStreakNumber(),
                            Players.LocalPlayer.UserId,
                            ProductController.getOwnedProducts()
                        )
                    end
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
    -- WARN: Wat
    if not (reward.Coins or reward.Gift) then
        warn("Don't know how to give reward", reward)
        return
    end

    local didRevert = false
    local maid = Maid.new()
    maid:GiveTask(function()
        didRevert = true
    end)

    if reward.Coins then
        local coins = reward.Coins * amount

        -- Coins
        CurrencyController.addCoins(coins)
        maid:GiveTask(function()
            CurrencyController.addCoins(-coins)
        end)

        -- World Effect
        UIController.getStateMachine():InvokeInState(function()
            if not didRevert then
                maid:GiveTask(Effects.coins(Effects.getCharacterAdornee(Players.LocalPlayer), COIN_EFFECT_DURATION))
            end
        end, UIConstants.States.HUD)

        -- Screen Add
        --TODO
    end

    if reward.Gift then
        warn("todo give gift reward", reward, amount)
        maid:GiveTask(function()
            warn("revoke gift reward", reward, amount)
        end)
    end

    return maid
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

function RewardsController.getDailyStreakNumber()
    return RewardsUtil.getDailyStreakNumber(getDailyStreakData())
end

-- DailyStreakUpdated
do
    DataController.Updated:Connect(function(event: string, _newValue: any)
        if event == "DailyStreakUpdated" then
            RewardsController.DailyStreakUpdated:Fire()
            RewardsController.promptDailyRewards(true)
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
