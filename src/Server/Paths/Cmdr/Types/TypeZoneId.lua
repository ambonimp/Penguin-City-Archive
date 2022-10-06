local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtil = require(ReplicatedStorage.Shared.Cmdr.CmdrUtil)
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local ZoneUtil = require(ReplicatedStorage.Shared.Zones.ZoneUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

return function(registry)
    -- We have to create a uniqe zoneId type for each zoneType
    for zoneType, zoneIds in pairs(ZoneConstants.ZoneId) do
        local function stringsGetter()
            return TableUtil.getKeys(zoneIds)
        end

        local function stringToObject(zoneId: string)
            return zoneId
        end

        local typeName = ZoneUtil.getZoneIdCmdrTypeName(zoneType)
        registry:RegisterType(typeName, CmdrUtil.createTypeDefinition(typeName, stringsGetter, stringToObject))
    end
end
