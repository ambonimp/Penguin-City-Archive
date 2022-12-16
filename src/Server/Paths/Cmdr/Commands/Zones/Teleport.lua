local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneUtil = require(ReplicatedStorage.Shared.Zones.ZoneUtil)
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)

return {
    Name = "teleport",
    Aliases = { "tp" },
    Description = "Teleports a player to a zone",
    Group = "|zonesAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to teleport",
        },
        {
            Type = ZoneUtil.getZoneTypeCmdrTypeName(ZoneConstants.ZoneCategory.Room),
            Name = "roomType",
            Description = "Room / Zone",
        },
    },
}
