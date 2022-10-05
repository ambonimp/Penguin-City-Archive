return {
    Name = "stopMinigame",
    Aliases = { "sm" },
    Description = "Stops a minigame for the passed players",
    Group = "zAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to stop minigames for",
        },
    },
}
