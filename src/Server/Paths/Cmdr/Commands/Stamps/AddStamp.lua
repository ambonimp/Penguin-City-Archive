local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StampUtil = require(ReplicatedStorage.Shared.Stamps.StampUtil)

return {
    Name = "addStamp",
    Aliases = {},
    Description = "Add a stamp",
    Group = "|stampsAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to add the stamp to",
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
