local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtil = require(ReplicatedStorage.Shared.Cmdr.CmdrUtil)
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local function stringsGetter()
    return TableUtil.toArray(ZoneConstants.ZoneCategory)
end

local function stringToObject(zoneCategory: string)
    return zoneCategory
end

return function(registry)
    registry:RegisterType("zoneCategory", CmdrUtil.createTypeDefinition("zoneCategory", stringsGetter, stringToObject))
end
