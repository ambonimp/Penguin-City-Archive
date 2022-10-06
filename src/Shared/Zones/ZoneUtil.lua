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
