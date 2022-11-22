local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtil = require(ReplicatedStorage.Shared.Cmdr.CmdrUtil)
local Stamps = require(ReplicatedStorage.Shared.Stamps.Stamps)

local function stringsGetter()
    return Stamps.StampTypes
end

local function stringToObject(stampType: string)
    return stampType
end

return function(registry)
    registry:RegisterType("stampType", CmdrUtil.createTypeDefinition("stampType", stringsGetter, stringToObject))
end
