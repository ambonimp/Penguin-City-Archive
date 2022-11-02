--[[
    Paychecks and Daily Rewards
]]
local RewardsController = {}

local Players = game:GetService("Players")
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
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local Sound = require(Paths.Shared.Sound)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)

local ATTRIBUTE_DAILY_REWARDS_VIEWPORT = "DailyRewardsViewport"
local COIN_EFFECT_DURATION = 3
local COLOR_WHITE = Color3.fromRGB(255, 255, 255)

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
    UIUtil.waitForHudAndRoomZone():andThen(function()
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

    local coins = reward.Coins or (reward.Gift and reward.Gift.Data.Coins)
    if coins then
        coins *= amount

        -- Coins
        CurrencyController.addCoins(coins)
        maid:GiveTask(function()
            CurrencyController.addCoins(-coins)
        end)

        -- From Reward
        if reward.Gift then
            UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.GiftPopup)
            UIController.getStateMachine():Push(UIConstants.States.GiftPopup, {
                Coins = coins,
            })
            maid:GiveTask(function()
                UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.GiftPopup)
            end)
        else
            Sound.play("Prize")
        end

        -- World Effect
        UIController.getStateMachine():InvokeInState(function()
            if not didRevert then
                maid:GiveTask(Effects.coins(Effects.getCharacterAdornee(Players.LocalPlayer), COIN_EFFECT_DURATION))
            end
        end, UIConstants.States.HUD)

        -- Screen Add
        --TODO

        return maid
    end

    if reward.Gift and reward.Gift.Data.ProductType and reward.Gift.Data.ProductId then
        local product = ProductUtil.getProduct(reward.Gift.Data.ProductType, reward.Gift.Data.ProductId)

        UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.GiftPopup)
        UIController.getStateMachine():Push(UIConstants.States.GiftPopup, {
            Product = product,
        })
        maid:GiveTask(function()
            UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.GiftPopup)
        end)

        return maid
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

-------------------------------------------------------------------------------
-- Paychecks
-------------------------------------------------------------------------------

function RewardsController.paycheckReceived(paycheckAmount: number, totalPaychecks: number)
    -- Display Paycheck
    UIUtil.waitForHudAndRoomZone():andThen(function()
        UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.Paycheck)
        UIController.getStateMachine():Push(UIConstants.States.Paycheck, {
            Amount = paycheckAmount,
            TotalPaychecks = totalPaychecks,
        })
    end)

    -- Add Coins after it's been cashed out
    UIController.getStateMachine():InvokeInState(function()
        CurrencyController.addCoins(paycheckAmount)
    end, UIConstants.States.HUD)
end

-------------------------------------------------------------------------------
-- Communication
-------------------------------------------------------------------------------

local function giftGiven(reward: RewardsConstants.DailyStreakReward)
    RewardsController.giveReward(reward, 1)
end

Remotes.bindEvents({
    GiftGiven = function(gift)
        local reward: RewardsConstants.DailyStreakReward = {
            Gift = gift,
            Color = COLOR_WHITE, -- Filler value to satisfying types
        }
        giftGiven(reward)
    end,
    PaycheckReceived = RewardsController.paycheckReceived,
})

return RewardsController
