local ZoneUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)

export type ZoneInstances = {
    Spawnpoint: BasePart?,
    MinigameDepartures: Folder?,
    MinigameArrivals: Folder?,
    RoomArrivals: Folder?,
    RoomDepartures: Folder?,
}

function ZoneUtil.zone(zoneType: string, zoneId: string)
    local zone: ZoneConstants.Zone = {
        ZoneType = zoneType,
        ZoneId = zoneId,
    }

    return zone
end

function ZoneUtil.getZoneModel(zone: ZoneConstants.Zone)
    if zone.ZoneType == ZoneConstants.ZoneType.Room then
        return game.Workspace.Rooms[zone.ZoneId]
    elseif zone.ZoneType == ZoneConstants.ZoneType.Minigame then
        return game.Workspace.Minigames[zone.ZoneId]
    end

    error(("ZoneType %q wat?"):format(zone.ZoneType))
end

function ZoneUtil.getZoneInstances(zone: ZoneConstants.Zone)
    local instance = ZoneUtil.getZoneModel(zone).ZoneInstances
    local zoneInstances: ZoneInstances = {
        Spawnpoint = instance:FindFirstChild("Spawnpoint"),
        MinigameDepartures = instance:FindFirstChild("MinigameDepartures"),
        MinigameArrivals = instance:FindFirstChild("MinigameArrivals"),
        RoomArrivals = instance:FindFirstChild("RoomArrivals"),
        RoomDepartures = instance:FindFirstChild("RoomDepartures"),
    }

    return zoneInstances
end

-- Returns a spawnpoint in the context of the zone we're leaving
function ZoneUtil.getSpawnpoint(fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone)
    local zoneInstances = ZoneUtil.getZoneInstances(toZone)
    local arrivals = zoneInstances[("%sArrivals"):format(fromZone.ZoneType)]
    if arrivals then
        local arrivalSpawnpoint = arrivals:FindFirstChild(fromZone.ZoneId)
        if arrivalSpawnpoint then
            return arrivalSpawnpoint
        end
    end

    return zoneInstances.Spawnpoint
end

function ZoneUtil.getZoneIdCmdrArgument(zoneTypeArgument)
    local zoneType = zoneTypeArgument:GetValue()
    return {
        Type = ZoneUtil.getZoneIdCmdrTypeName(zoneType),
        Name = "zoneId",
        Description = ("zoneId (%s)"):format(zoneType),
    }
end

function ZoneUtil.getZoneIdCmdrTypeName(zoneType: string)
    return StringUtil.toCamelCase(("%sZoneId"):format(zoneType))
end

return ZoneUtil
