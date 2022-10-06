local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtil = require(ReplicatedStorage.Shared.Cmdr.CmdrUtil)
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local function stringsGetter()
    return TableUtil.toArray(ZoneConstants.ZoneType)
end

local function stringToObject(zoneType: string)
    return zoneType
end

return function(registry)
    registry:RegisterType("zoneType", CmdrUtil.createTypeDefinition("zoneType", stringsGetter, stringToObject))
end
