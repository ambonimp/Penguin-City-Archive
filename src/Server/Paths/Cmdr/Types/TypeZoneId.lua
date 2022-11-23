local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtil = require(ReplicatedStorage.Shared.Cmdr.CmdrUtil)
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local ZoneUtil = require(ReplicatedStorage.Shared.Zones.ZoneUtil)

return function(registry)
    -- We have to create a uniqe zoneId type for each zoneType
    for zoneType, zoneIds in pairs(ZoneConstants.ZoneId) do
        local function stringsGetter()
            local cleanedZoneIds: { string } = {}
            for _, zoneId in pairs(zoneIds) do
                -- Don't show player igloos for this - thats a different command!
                if not ZoneUtil.isHouseInteriorZone(ZoneUtil.zone(zoneType, zoneId)) then
                    table.insert(cleanedZoneIds, zoneId)
                end
            end

            return cleanedZoneIds
        end

        local function stringToObject(zoneId: string)
            return zoneId
        end

        local typeName = ZoneUtil.getZoneIdCmdrTypeName(zoneType)
        registry:RegisterType(typeName, CmdrUtil.createTypeDefinition(typeName, stringsGetter, stringToObject))
    end
end
