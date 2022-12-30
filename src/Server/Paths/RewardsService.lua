--[[
    Paychecks and Daily Rewards
]]
local RewardsService = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local PlayerService = require(Paths.Server.PlayerService)
local DataService = require(Paths.Server.Data.DataService)
local RewardsUtil = require(Paths.Shared.Rewards.RewardsUtil)
local RewardsConstants = require(Paths.Shared.Rewards.RewardsConstants)
local Remotes = require(Paths.Shared.Remotes)
local CurrencyService = require(Paths.Server.CurrencyService)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local ProductService = require(Paths.Server.Products.ProductService)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local Signal = require(Paths.Shared.Signal)
local CurrencyConstants = require(Paths.Shared.Currency.CurrencyConstants)

local UPDATE_DAILY_REWARD_EVERY = 5 * 60

RewardsService.GavePaycheck = Signal.new() -- { player: Player, paycheckNumber: number }
RewardsService.ClaimedDailyReward = Signal.new() -- { player: Player, dayNumber: number }

local totalPaychecksByPlayer: { [Player]: number } = {}

local function getDailyRewardData(player: Player)
    return DataService.get(player, RewardsUtil.getDailyRewardDataAddress())
end

--[[
    Updates a players daily streak, calculating if their streak should be increased, expired etc..
    Informs the client if anything has changed.
]]
function RewardsService.updateDailyReward(player: Player)
    local dailyRewardData = getDailyRewardData(player)
    local updatedDailyRewardData = RewardsUtil.getUpdatedDailyReward(dailyRewardData)

    -- Streak updated!
    local hasStreakNumberMismatch = RewardsUtil.getDailyRewardNumber(dailyRewardData)
        ~= RewardsUtil.getDailyRewardNumber(updatedDailyRewardData)
    local hasDaysMismatch = RewardsUtil.getDailyRewardDays(dailyRewardData) ~= RewardsUtil.getDailyRewardDays(updatedDailyRewardData)
    if hasStreakNumberMismatch or hasDaysMismatch then
        DataService.set(player, RewardsUtil.getDailyRewardDataAddress(), updatedDailyRewardData, "DailyRewardUpdated")
    end
end

function RewardsService.addDailyReward(player: Player, days: number)
    RewardsService.updateDailyReward(player)
    for _ = 1, days do
        RewardsUtil.setDailyRewardRenewTime(DataService.get(player, RewardsUtil.getDailyRewardDataAddress()), 0)
        RewardsService.updateDailyReward(player)
    end
end

-- Returns true if successful, false o/w (e.g., is now offline)
function RewardsService.givePaycheck(player: Player)
    -- RETURN: Player is gone!
    if not (totalPaychecksByPlayer[player] and player:IsDescendantOf(Players)) then
        return false
    end

    -- Give Paycheck
    local totalPaychecks = totalPaychecksByPlayer[player] + 1
    totalPaychecksByPlayer[player] = totalPaychecks

    local paycheckAmount = math.clamp(
        RewardsConstants.Paycheck.Coins.Base + RewardsConstants.Paycheck.Coins.Add * (totalPaychecks - 1),
        0,
        RewardsConstants.Paycheck.Coins.Max
    )
    CurrencyService.injectCoins(player, paycheckAmount, {
        IsClientOblivious = false,
        InjectCategory = CurrencyConstants.InjectCategory.Paycheck,
    })

    -- Inform
    RewardsService.GavePaycheck:Fire(player, totalPaychecks)
    Remotes.fireClient(player, "PaycheckReceived", paycheckAmount, totalPaychecks)

    return true
end
Remotes.declareEvent("PaycheckReceived")

function RewardsService.loadPlayer(player: Player)
    -- Daily Streak
    RewardsService.updateDailyReward(player)

    task.spawn(function()
        -- While player is online, check every UPDATE_DAILY_REWARD_EVERY when their daily streak renews - and schedule an update if so
        while player:IsDescendantOf(Players) do
            local timeUntilNextDailyRewardRenew = RewardsUtil.getTimeUntilNextDailyRewardRenew(getDailyRewardData(player))
            if timeUntilNextDailyRewardRenew < UPDATE_DAILY_REWARD_EVERY then
                task.delay(timeUntilNextDailyRewardRenew + 1, function() -- +1 for extra leeway
                    RewardsService.updateDailyReward(player)
                end)
            end

            task.wait(UPDATE_DAILY_REWARD_EVERY)
        end
    end)

    -- Paycheck
    totalPaychecksByPlayer[player] = 0
    PlayerService.getPlayerMaid(player):GiveTask(function()
        totalPaychecksByPlayer[player] = nil
    end)

    task.spawn(function()
        while task.wait(RewardsConstants.Paycheck.EverySeconds) do
            if RewardsService.givePaycheck(player) == false then
                break
            end
        end
    end)
end

-- Gives a reward on the server - assumes client knows this is happening
function RewardsService.giveReward(player: Player, reward: RewardsConstants.DailyRewardReward, amount: number)
    local coins = reward.Coins or (reward.Gift and reward.Gift.Data.Coins)
    if coins then
        coins *= amount

        CurrencyService.injectCoins(player, coins, {
            IsClientOblivious = false,
            InjectCategory = CurrencyConstants.InjectCategory.DailyReward,
        })
        return
    end

    if reward.Gift and reward.Gift.Data.ProductType and reward.Gift.Data.ProductId then
        local product = ProductUtil.getProduct(reward.Gift.Data.ProductType, reward.Gift.Data.ProductId)
        ProductService.addProduct(player, product)
        return
    end

    warn("Don't know how to give reward", reward)
end

-- Custom function to give a gift to a player, that informs the client!
function RewardsService.giveGift(player: Player, giftName: string)
    local reward = RewardsUtil.getDailyRewardGift(
        math.random(1, 100),
        math.random(1, 100),
        math.random(1, 100),
        ProductService.getOwnedProducts(player),
        giftName
    )

    RewardsService.giveReward(player, reward, 1)
    Remotes.fireClient(player, "GiftGiven", reward.Gift)
end
Remotes.declareEvent("GiftGiven")

-- Communication
do
    Remotes.bindFunctions({
        ClaimDailyRewardRequest = function(player: Player, dirtyUnclaimedDays: any)
            -- FALSE: Not a table
            if typeof(dirtyUnclaimedDays) ~= "table" then
                return false
            end

            -- Convert to integer dict
            dirtyUnclaimedDays = TableUtil.mapKeys(dirtyUnclaimedDays, function(key)
                return tonumber(key)
            end)

            -- FALSE: Mismatch
            local unclaimedDays = RewardsUtil.getUnclaimedDailyRewardDays(getDailyRewardData(player))
            for dayNum, amount in pairs(unclaimedDays) do
                if not (dirtyUnclaimedDays[dayNum] == amount) then
                    warn("Mismatch", dirtyUnclaimedDays, unclaimedDays)
                    return false
                end
            end

            -- RETURN: Empty
            if TableUtil.isEmpty(unclaimedDays) then
                return
            end

            -- Hand over stuffs
            local highestDayNum: number
            for dayNum, amount in pairs(unclaimedDays) do
                local reward = RewardsUtil.getDailyRewardReward(dayNum)
                if reward.Gift then
                    reward = RewardsUtil.getDailyRewardGift(
                        dayNum,
                        RewardsUtil.getDailyRewardNumber(getDailyRewardData(player)),
                        player.UserId,
                        ProductService.getOwnedProducts(player)
                    )
                end

                RewardsService.giveReward(player, reward, amount)

                if not highestDayNum or dayNum > highestDayNum then
                    highestDayNum = dayNum
                end
            end

            -- Inform
            RewardsService.ClaimedDailyReward:Fire(player, highestDayNum)

            -- Data
            local unclaimedAddress = ("%s.%s"):format(RewardsUtil.getDailyRewardDataAddress(), "Unclaimed")
            DataService.set(player, unclaimedAddress, {}, "DailyRewardUpdated")

            return true
        end,
    })
end

return RewardsService
