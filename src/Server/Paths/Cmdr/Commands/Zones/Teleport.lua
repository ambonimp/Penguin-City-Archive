local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneUtil = require(ReplicatedStorage.Shared.Zones.ZoneUtil)

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
            Type = "zoneCategory",
            Name = "zoneCategory",
            Description = "zoneCategory",
        },
        function(context)
            local zoneCategoryArgument = context:GetArgument(2)
            return ZoneUtil.getZoneTypeCmdrArgument(zoneCategoryArgument)
        end,
    },
}
