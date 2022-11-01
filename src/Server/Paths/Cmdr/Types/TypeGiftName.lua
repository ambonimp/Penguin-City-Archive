local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtil = require(ReplicatedStorage.Shared.Cmdr.CmdrUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local RewardsConstants = require(ReplicatedStorage.Shared.Rewards.RewardsConstants)

local function stringsGetter()
    return TableUtil.toArray(RewardsConstants.GiftNames)
end

local function stringToObject(giftName: string)
    return giftName
end

return function(registry)
    registry:RegisterType("giftName", CmdrUtil.createTypeDefinition("giftName", stringsGetter, stringToObject))
end
