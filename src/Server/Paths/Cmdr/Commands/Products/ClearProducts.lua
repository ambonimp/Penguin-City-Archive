return {
    Name = "clearProducts",
    Aliases = {},
    Description = "Clears all products from players",
    Group = "|productsAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to clear all products from",
        },
        {
            Type = "boolean",
            Name = "kickPlayer",
            Description = "Whether to kick the player as part of this operation",
            Default = false,
        },
    },
}
