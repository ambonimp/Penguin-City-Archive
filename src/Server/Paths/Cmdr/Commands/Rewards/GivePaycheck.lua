return {
    Name = "givePaycheck",
    Aliases = {},
    Description = "Gives a player their next paycheck",
    Group = "|rewardsAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to give paychecks to",
        },
    },
}
