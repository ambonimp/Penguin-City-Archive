return {
    Name = "addCoins",
    Aliases = {},
    Description = "Adds coins",
    Group = "|coinsAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to add coins to",
        },
        {
            Type = "number",
            Name = "addCoins",
            Description = "How many coins to add",
        },
    },
}
