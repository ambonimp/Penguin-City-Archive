return {
    Name = "addDailyStreak",
    Aliases = {},
    Description = "Adds days to a players dailystreak",
    Group = "|rewardsAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to add days to",
        },
        {
            Type = "number",
            Name = "days",
            Description = "How many days to add",
        },
    },
}
