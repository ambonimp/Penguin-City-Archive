return {
    Name = "setCoins",
    Aliases = {},
    Description = "Sets coins",
    Group = "|coinsAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to set the coins of",
        },
        {
            Type = "number",
            Name = "coins",
            Description = "What value to set their coins to",
        },
    },
}
