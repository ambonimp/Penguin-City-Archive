local StampUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stamps = require(ReplicatedStorage.Shared.Stamps.Stamps)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local StampConstants = require(ReplicatedStorage.Shared.Stamps.StampConstants)

local totalStamps: number

function StampUtil.getStampFromId(stampId: string)
    -- Infer StampType
    local stampType: Stamps.StampType
    for _, someStampType in pairs(Stamps.StampTypes) do
        if StringUtil.startsWith(stampId, string.lower(someStampType)) then
            stampType = someStampType
            break
        end
    end

    -- WARN: Definitely a bad stampId
    if not stampType then
        warn(("Bad stampId %q; not prefixed with a proper stampType (lowercase)"):format(stampId))
        return nil
    end

    for _, stamp in pairs(StampUtil.getStampsFromType(stampType)) do
        if stamp.Id == stampId then
            return stamp
        end
    end

    warn(("Bad stampId %q; could not find in %q Stamps"):format(stampId, stampType))
    return nil
end

function StampUtil.getStampsFromType(stampType: Stamps.StampType): { Stamps.Stamp }
    return require(ReplicatedStorage.Shared.Stamps.StampTypes:FindFirstChild(("%sStamps"):format(stampType)))
end

function StampUtil.getTotalStamps()
    return totalStamps
end

function StampUtil.getStampDataAddress(stampId: string)
    return ("Stamps.OwnedStamps.%s"):format(stampId)
end

function StampUtil.getStampBookDataDefaults()
    return {
        CoverColor = {
            Unlocked = { "Brown" },
            Selected = "Brown",
        },
        CoverPattern = {
            Unlocked = { "Voldex" },
            Selected = "Voldex",
        },
        TextColor = {
            Unlocked = { "White" },
            Selected = "White",
        },
        Seal = {
            Unlocked = { "Gold" },
            Selected = "Gold",
        },
        CoverStampIds = {},
    }
end

function StampUtil.getStampIdCmdrArgument(stampTypeArgument)
    local stampType = stampTypeArgument:GetValue()
    return {
        Type = StampUtil.getStampIdCmdrTypeName(stampType),
        Name = "stampId",
        Description = ("stampId (%s)"):format(stampType),
    }
end

function StampUtil.getStampIdCmdrTypeName(stampType: string)
    return StringUtil.toCamelCase(("%sStampId"):format(stampType))
end

-- Calculations
do
    totalStamps = 0
    for _, stampModules in pairs(ReplicatedStorage.Shared.Stamps.StampTypes:GetChildren()) do
        totalStamps += #require(stampModules)
    end
end

return StampUtil
