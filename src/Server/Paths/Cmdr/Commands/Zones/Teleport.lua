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
            Type = "zoneType",
            Name = "zoneType",
            Description = "zoneType",
        },
        function(context)
            local zoneTypeArgument = context:GetArgument(2)
            return ZoneUtil.getZoneIdCmdrArgument(zoneTypeArgument)
        end,
    },
}
