return {
    Name = "getProducts",
    Aliases = {},
    Description = "Outputs what products a player owns",
    Group = "zAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to query",
        },
    },
}
