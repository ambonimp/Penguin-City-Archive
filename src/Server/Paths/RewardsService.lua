--[[
    Paychecks and Daily Rewards
]]
local RewardsService = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local DataService = require(Paths.Server.Data.DataService)
local RewardsUtil = require(Paths.Shared.Rewards.RewardsUtil)
local RewardsConstants = require(Paths.Shared.Rewards.RewardsConstants)
local PlayerService = require(Paths.Server.PlayerService)
local Remotes = require(Paths.Shared.Remotes)
local CurrencySevice = require(Paths.Server.CurrencyService)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local ProductService = require(Paths.Server.Products.ProductService)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)

local totalPaychecksByPlayer: { [Player]: number } = {}

local function getDailyStreakData(player: Player)
    return DataService.get(player, RewardsUtil.getDailyStreakDataAddress())
end

--[[
    Updates a players daily streak, calculating if their streak should be increased, expired etc..
    Informs the client.
]]
function RewardsService.updateDailyStreak(player: Player)
    local dailyStreakData = getDailyStreakData(player)
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

-- Returns true if successful, false o/w (e.g., is now offline)
function RewardsService.givePaycheck(player: Player)
    -- RETURN: Player is gone!
    if not (totalPaychecksByPlayer[player] and player:IsDescendantOf(Players)) then
        return
    end

    -- Give Paycheck
    local totalPaychecks = totalPaychecksByPlayer[player] + 1
    totalPaychecksByPlayer[player] = totalPaychecks

    local paycheckAmount = math.clamp(
        RewardsConstants.Paycheck.Coins.Base + RewardsConstants.Paycheck.Coins.Add * (totalPaychecks - 1),
        0,
        RewardsConstants.Paycheck.Coins.Max
    )
    CurrencySevice.addCoins(player, paycheckAmount)

    -- Inform
    Remotes.fireClient(player, "PaycheckReceived", paycheckAmount)
end
Remotes.declareEvent("PaycheckReceived")

function RewardsService.loadPlayer(player: Player)
    -- Daily Streak
    RewardsService.updateDailyStreak(player)
    PlayerService.getPlayerMaid(player):GiveTask(function()
        RewardsService.updateDailyStreak(player)
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
function RewardsService.giveReward(player: Player, reward: RewardsConstants.DailyStreakReward, amount: number)
    local coins = reward.Coins or (reward.Gift and reward.Gift.Data.Coins)
    if coins then
        coins *= amount

        CurrencySevice.addCoins(player, coins)
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
    local reward = RewardsUtil.getDailyStreakGift(
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
        ClaimDailyStreakRequest = function(player: Player, dirtyUnclaimedDays: any)
            -- FALSE: Not a table
            if typeof(dirtyUnclaimedDays) ~= "table" then
                return false
            end

            -- Convert to integer dict
            dirtyUnclaimedDays = TableUtil.mapKeys(dirtyUnclaimedDays, function(key)
                return tonumber(key)
            end)

            -- FALSE: Mismatch
            local unclaimedDays = RewardsUtil.getUnclaimedDailyStreakDays(getDailyStreakData(player))
            for dayNum, amount in pairs(unclaimedDays) do
                if not (dirtyUnclaimedDays[dayNum] == amount) then
                    warn("Mismatch", dirtyUnclaimedDays, unclaimedDays)
                    return false
                end
            end

            -- Hand over stuffs
            for dayNum, amount in pairs(unclaimedDays) do
                local reward = RewardsUtil.getDailyStreakReward(dayNum)
                if reward.Gift then
                    reward = RewardsUtil.getDailyStreakGift(
                        dayNum,
                        RewardsUtil.getDailyStreakNumber(getDailyStreakData(player)),
                        player.UserId,
                        ProductService.getOwnedProducts(player)
                    )
                end

                RewardsService.giveReward(player, reward, amount)
            end

            local unclaimedAddress = ("%s.%s"):format(RewardsUtil.getDailyStreakDataAddress(), "Unclaimed")
            DataService.set(player, unclaimedAddress, {}, "DailyStreakUpdated")

            return true
        end,
    })
end

return RewardsService
