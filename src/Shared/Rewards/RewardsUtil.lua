local RewardsUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local DataUtil = require(ReplicatedStorage.Shared.Utils.DataUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local RewardsConstants = require(ReplicatedStorage.Shared.Rewards.RewardsConstants)
local TimeUtil = require(ReplicatedStorage.Shared.Utils.TimeUtil)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local ProductUtil = require(ReplicatedStorage.Shared.Products.ProductUtil)
local Products = require(ReplicatedStorage.Shared.Products.Products)

export type DailyStreakEntry = {
    StreakNumber: number,
    Days: number,
    RenewAtServerTime: number,
    ExpiresAtServerTime: number,
}

local GIFT_ATTEMPTS = 10

function RewardsUtil.getDailyStreakNumber(dailyStreakData: DataUtil.Data)
    local entry = dailyStreakData.Entries["1"] :: DailyStreakEntry
    if entry then
        return entry.StreakNumber
    end
    return 0
end

function RewardsUtil.getDailyStreakDays(dailyStreakData: DataUtil.Data)
    local entry = dailyStreakData.Entries["1"] :: DailyStreakEntry
    if entry then
        return entry.Days
    end
    return 0
end

function RewardsUtil.getBestDailyStreak(dailyStreakData: DataUtil.Data): number
    return dailyStreakData.BestStreak
end

function RewardsUtil.getTimeUntilNextDailyStreakRenew(dailyStreakData: DataUtil.Data)
    local entry = dailyStreakData.Entries["1"] :: DailyStreakEntry
    if entry then
        return math.clamp(entry.RenewAtServerTime - Workspace:GetServerTimeNow(), 0, math.huge)
    end
    return 0
end

function RewardsUtil.getUnclaimedDailyStreakDays(dailyStreakData: DataUtil.Data): { [number]: number }
    return TableUtil.mapKeys(dailyStreakData.Unclaimed, function(key)
        return tonumber(key)
    end)
end

--[[
    dailyStreakData = {
        Entries = {},
        Unclaimed = {},
    }
]]
function RewardsUtil.getUpdatedDailyStreak(dailyStreakData: DataUtil.Data)
    -- Convert to array for easier manipulation
    local arrayDailyStreakEntries: { DailyStreakEntry } = TableUtil.mapKeys(TableUtil.deepClone(dailyStreakData.Entries), function(key)
        return tonumber(key)
    end)
    local now = Workspace:GetServerTimeNow()

    -- Cull old entries
    for i = #arrayDailyStreakEntries, 1, -1 do
        local entry = arrayDailyStreakEntries[i]
        local expiredTime = now - entry.ExpiresAtServerTime
        local hasExpired = expiredTime > 0

        if hasExpired then
            -- Very old; remove
            if expiredTime > TimeUtil.daysToSeconds(RewardsConstants.DailyStreak.StoreMaxDays) then
                table.remove(arrayDailyStreakEntries, i)
            end
        end
    end

    -- Ensure good entry is at the top
    local entry = arrayDailyStreakEntries[1]
    local streakNumber = entry and entry.StreakNumber or 0
    if not entry or (entry.ExpiresAtServerTime < now) then
        entry = {
            StreakNumber = streakNumber + 1,
            Days = 0,
            RenewAtServerTime = 0,
            ExpiresAtServerTime = 0,
        }
        table.insert(arrayDailyStreakEntries, 1, entry)
    end

    -- Try renew
    if entry.RenewAtServerTime < now then
        entry.Days += 1
        dailyStreakData.Unclaimed[tostring(entry.Days)] = (dailyStreakData.Unclaimed[tostring(entry.Days)] or 0) + 1

        entry.RenewAtServerTime = now + TimeUtil.hoursToSeconds(RewardsConstants.DailyStreak.RenewAfterHours)
        entry.ExpiresAtServerTime = entry.RenewAtServerTime + TimeUtil.hoursToSeconds(RewardsConstants.DailyStreak.ExpireAfterHours)
    end

    return {
        Entries = TableUtil.mapKeys(arrayDailyStreakEntries, function(key)
            return tostring(key)
        end),
        Unclaimed = dailyStreakData.Unclaimed,
        BestStreak = math.max(dailyStreakData.BestStreak, entry.Days),
    }
end

-- Cheeky utlility to change the time this dailyStreakData can renew
function RewardsUtil.setDailyStreakRenewTime(dailyStreakData: DataUtil.Data, renewTime: number)
    local entry = dailyStreakData.Entries["1"] :: DailyStreakEntry
    if entry then
        entry.RenewAtServerTime = renewTime
    end
end

function RewardsUtil.getDailyStreakReward(day: number)
    local wrappedDay = MathUtil.wrapAround(day, #RewardsConstants.DailyStreak.Rewards)
    local rewardLevel = math.ceil(day / #RewardsConstants.DailyStreak.Rewards)

    local reward = RewardsConstants.DailyStreak.Rewards[wrappedDay]
    if reward.Gift then
        reward.Gift.Name = rewardLevel == 1 and RewardsConstants.GiftNames["Small Gift"]
            or rewardLevel == 2 and RewardsConstants.GiftNames["Medium Gift"]
            or rewardLevel == 3 and RewardsConstants.GiftNames["Large Gift"]
            or (rewardLevel % 2 == 0) and RewardsConstants.GiftNames["Rare Gift"] -- 4, 6, 8, ...
            or RewardsConstants.GiftNames["Extraordinary Gift"] -- 5, 7, 9, ...
    end

    return reward
end

--[[
    - `productBlacklist` `productIds: amount`
    - `streakNumber` and `seedContribution` helps keep gifts random between players and playtime
]]
function RewardsUtil.getDailyStreakGift(
    day: number,
    streakNumber: number,
    seedContribution: number?,
    productBlacklist: { [Products.Product]: number }?
)
    -- ERROR: Not a gift!
    local reward = RewardsUtil.getDailyStreakReward(day)
    if not (reward.Gift and reward.Gift.Name) then
        warn(reward)
        error(("Cannot get Gift for day %d; not a gift reward day or .Name was not defined!"):format(day))
    end

    -- Get our Random for this context
    local seed = streakNumber * 1000000 + day + (seedContribution or 0) -- Unique enough seed for our purposes
    local random = Random.new(seed)

    local function isProductAllowed(product: Products.Product)
        if not productBlacklist then
            return true
        end

        if productBlacklist[product.Id] and productBlacklist[product.Id] > 0 then
            return false
        end

        return true
    end

    -- Select a gift from weight
    reward.Gift.Data = {}
    while TableUtil.isEmpty(reward.Gift.Data) do
        local gifts = RewardsConstants.Gifts[reward.Gift.Name]

        local weightedGifts: { {
            Weight: number,
            Value: any,
        } } = {}
        for _, gift in pairs(gifts) do
            table.insert(weightedGifts, {
                Weight = gift.Weight,
                Value = gift,
            })
        end
        local gift: RewardsConstants.Gift = MathUtil.weightedChoice(weightedGifts, random)

        -- Write to Reward
        reward.Gift.Type = gift.Type

        if gift.Type == "Coins" then
            reward.Gift.Data.Coins = gift.Data.Coins
        elseif gift.Type == "Clothing" then
            for _ = 1, GIFT_ATTEMPTS do
                local itemNames, categoryName = TableUtil.getRandom(gift.Data.Clothing)
                local itemName = TableUtil.getRandom(itemNames)
                local product = ProductUtil.getCharacterItemProduct(categoryName, itemName)

                if isProductAllowed(product) then
                    reward.Gift.Data.ProductId = product.Id
                    reward.Gift.Data.ProductType = product.Type
                    break
                end
            end
        elseif gift.Type == "House" then
            for _ = 1, GIFT_ATTEMPTS do
                local objectNames, categoryName = TableUtil.getRandom(gift.Data.House)
                local objectName = TableUtil.getRandom(objectNames)
                local product = ProductUtil.getHouseObjectProduct(categoryName, objectName)

                if isProductAllowed(product) then
                    reward.Gift.Data.ProductId = product.Id
                    reward.Gift.Data.ProductType = product.Type
                    break
                end
            end
        elseif gift.Type == "Outfit" then
            for _ = 1, GIFT_ATTEMPTS do
                local outfitName = TableUtil.getRandom(gift.Data.Outfit)
                local product = ProductUtil.getCharacterItemProduct("Outfit", outfitName)

                if isProductAllowed(product) then
                    reward.Gift.Data.ProductId = product.Id
                    reward.Gift.Data.ProductType = product.Type
                    break
                end
            end
        else
            error(("Missing case for gift type %q"):format(gift.Type))
        end
    end

    return reward
end

function RewardsUtil.getDailyStreakDataAddress()
    return "Rewards.DailyStreak"
end

return RewardsUtil
