local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RewardsConstants = require(ReplicatedStorage.Shared.Rewards.RewardsConstants)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local CharacterItems = require(ReplicatedStorage.Shared.Constants.CharacterItems)
local HouseObjects = require(ReplicatedStorage.Shared.Constants.HouseObjects)

local BAD_CLOTHING_CHARACTER_ITEM_CATEGORIES = {
    "BodyType",
    "Outfit",
}

return function()
    local issues: { string } = {}

    -- DailyStreakRewards Coins OR Gift
    for i, reward in pairs(RewardsConstants.DailyStreak.Rewards) do
        local totalOptions = (reward.Coins and 1 or 0) + (reward.Gift and 1 or 0)
        if totalOptions ~= 1 then
            table.insert(issues, ("DailyStreak.Rewards.%s must have `Coins` OR `Gift` defined"):format(tostring(i)))
        end
    end

    local function verifyGift(giftName: string, index: number, gift: RewardsConstants.Gift)
        -- Type
        if not table.find(RewardsConstants.GiftTypes, gift.Type) then
            table.insert(issues, ("%s.%d has bad .Type"):format(giftName, index))
            return
        end

        -- Weight
        if not (gift.Weight and gift.Weight > 0) then
            table.insert(issues, ("%s.%d needs a position integer for .Weight"):format(giftName, index))
        end

        -- Data
        if gift.Data and gift.Data[gift.Type] and TableUtil.length(gift.Data) == 1 then
            if gift.Type == "Coins" then
                -- COINS
                if not (gift.Data.Coins and gift.Data.Coins > 0) then
                    table.insert(issues, ("%s.%d needs a positive Data.Coins value!"):format(giftName, index))
                end
            elseif gift.Type == "Clothing" then
                -- CLOTHING
                if gift.Data.Clothing and typeof(gift.Data.Clothing) == "table" then
                    for categoryName, itemNames in pairs(gift.Data.Clothing) do
                        categoryName = tostring(categoryName)
                        local category = CharacterItems[categoryName]
                        if category then
                            if table.find(BAD_CLOTHING_CHARACTER_ITEM_CATEGORIES, categoryName) then
                                table.insert(
                                    issues,
                                    ("%s.%d Data.Clothing %q is a banned categoryName"):format(giftName, index, categoryName)
                                )
                            end

                            for _, itemName in pairs(itemNames) do
                                itemName = tostring(itemName)
                                if not category.Items[itemName] then
                                    table.insert(
                                        issues,
                                        ("%s.%d Data.Clothing.%s has a bad itemName %q"):format(giftName, index, categoryName, itemName)
                                    )
                                end
                            end
                        else
                            table.insert(issues, ("%s.%d Data.Clothing %q is a bad category!"):format(giftName, index, categoryName))
                        end
                    end
                else
                    table.insert(issues, ("%s.%d needs a { [string]: { string } } at Data.Clothing"):format(giftName, index))
                end
            elseif gift.Type == "House" then
                -- HOUSE
                if gift.Data.House and typeof(gift.Data.House) == "table" then
                    for categoryName, objectNames in pairs(gift.Data.House) do
                        categoryName = tostring(categoryName)
                        local category = HouseObjects[categoryName]
                        if category then
                            for _, objectName in pairs(objectNames) do
                                objectName = tostring(objectName)
                                if not category.Objects[objectName] then
                                    table.insert(
                                        issues,
                                        ("%s.%d Data.House.%s has a bad itemName %q"):format(giftName, index, categoryName, objectName)
                                    )
                                end
                            end
                        else
                            table.insert(issues, ("%s.%d Data.House %q is a bad category!"):format(giftName, index, categoryName))
                        end
                    end
                else
                    table.insert(issues, ("%s.%d needs a { [string]: { string } } at Data.House"):format(giftName, index))
                end
            elseif gift.Type == "Outfit" then
                -- OUTFIT
                if gift.Data.Outfit and typeof(gift.Data.Outfit) == "table" then
                    for _, outfitName in pairs(gift.Data.Outfit) do
                        outfitName = tostring(outfitName)
                        if not CharacterItems.Outfit.Items[outfitName] then
                            table.insert(issues, ("%s.%d Data.Outfit has a bad outfitName %q"):format(giftName, index, outfitName))
                        end
                    end
                else
                    table.insert(issues, ("%s.%d needs a { string } at Data.Outfit"):format(giftName, index))
                end
            else
                error(("Missing case for gift type %q"):format(gift.Type))
            end
        else
            table.insert(issues, ("%s.%d needs a Data.%s entry, and only this!"):format(giftName, index, gift.Type))
        end
    end

    -- Gifts
    for giftName, gifts in pairs(RewardsConstants.Gifts) do
        -- GiftName
        if not RewardsConstants.GiftNames[giftName] then
            table.insert(issues, ("%q is a bad giftName"):format(giftName))
        end

        local hasCoinGift = false
        for index, gift in pairs(gifts) do
            verifyGift(giftName, index, gift)

            if gift.Type == "Coins" then
                hasCoinGift = true
            end
        end

        if not hasCoinGift then
            table.insert(issues, ("Gift %q needs a Coins gift!"):format(giftName))
        end
    end

    local totalGiftNames = TableUtil.length(RewardsConstants.GiftNames)
    local totalGifts = TableUtil.length(RewardsConstants.Gifts)
    if totalGiftNames ~= totalGifts then
        table.insert(issues, ("%d GiftNames, %d Gifts listed - must be the same!"):format(totalGiftNames, totalGifts))
    end

    return issues
end
