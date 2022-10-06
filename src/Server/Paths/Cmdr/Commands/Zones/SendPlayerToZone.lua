local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneUtil = require(ReplicatedStorage.Shared.Zones.ZoneUtil)

return {
    Name = "sendPlayerToZone",
    Aliases = {},
    Description = "Sends a player to a zone",
    Group = "|zonesAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to send",
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
