return {
    Name = "setCoins",
    Aliases = {},
    Description = "Sets coins",
    Group = "zAdmin",
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
