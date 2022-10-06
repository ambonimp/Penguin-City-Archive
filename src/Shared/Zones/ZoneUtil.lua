local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneUtil = {}

local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)

export type ZoneInstances = {
    Spawnpoint: BasePart?,
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
    }

    return zoneInstances
end

return ZoneUtil
