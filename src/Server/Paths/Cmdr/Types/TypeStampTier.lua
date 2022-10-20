local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtil = require(ReplicatedStorage.Shared.Cmdr.CmdrUtil)
local Stamps = require(ReplicatedStorage.Shared.Stamps.Stamps)

local function stringsGetter()
    return Stamps.StampTiers
end

local function stringToObject(stampTier: string)
    return stampTier
end

return function(registry)
    registry:RegisterType("stampTier", CmdrUtil.createTypeDefinition("stampTier", stringsGetter, stringToObject))
end
