local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StampUtil = require(ReplicatedStorage.Shared.Stamps.StampUtil)

return {
    Name = "hasStamp",
    Aliases = {},
    Description = "Checks if a player owns a stamp",
    Group = "|stampsAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to check",
        },
        {
            Type = "stampType",
            Name = "stampType",
            Description = "stampType",
        },
        function(context)
            local stampTypeArgument = context:GetArgument(2)
            return StampUtil.getStampIdCmdrArgument(stampTypeArgument)
        end,
        {
            Type = "stampTier",
            Name = "stampTier",
            Description = "stampTier",
            Optional = true,
        },
    },
}
