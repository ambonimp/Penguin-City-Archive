local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StampUtil = require(ReplicatedStorage.Shared.Stamps.StampUtil)

return {
    Name = "revokeStamp",
    Aliases = {},
    Description = "Revokes a stamp",
    Group = "|stampsAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to revoke the stamp from",
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
    },
}
