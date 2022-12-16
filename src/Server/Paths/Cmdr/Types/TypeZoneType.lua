local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtil = require(ReplicatedStorage.Shared.Cmdr.CmdrUtil)
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local ZoneUtil = require(ReplicatedStorage.Shared.Zones.ZoneUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

return function(registry)
    -- We have to create a uniqe zoneType type for each zoneCategory
    for zoneCategory, zoneTypes in pairs(ZoneConstants.ZoneType) do
        local function stringsGetter()
            return TableUtil.getKeys(zoneTypes)
        end

        local function stringToObject(zoneType: string)
            return zoneType
        end

        local typeName = ZoneUtil.getZoneTypeCmdrTypeName(zoneCategory)
        registry:RegisterType(typeName, CmdrUtil.createTypeDefinition(typeName, stringsGetter, stringToObject))
    end
end
