local StampUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stamps = require(ReplicatedStorage.Shared.Stamps.Stamps)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)

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

    return nil
end

function StampUtil.getStampsFromType(stampType: Stamps.StampType): { Stamps.Stamp }
    return require(ReplicatedStorage.Shared.Stamps.StampTypes:FindFirstChild(("%sStamps"):format(stampType)))
end

return StampUtil
