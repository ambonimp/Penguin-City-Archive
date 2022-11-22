return {
    Name = "addDailyReward",
    Aliases = {},
    Description = "Adds days to a players dailyreward",
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
            Default = 1,
            Description = "How many days to add",
        },
    },
}
