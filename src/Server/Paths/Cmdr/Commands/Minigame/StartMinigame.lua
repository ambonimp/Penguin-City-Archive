return {
    Name = "startMinigame",
    Aliases = { "sm" },
    Description = "Starts a minigame for the passed players",
    Group = "|minigameAdmin",
    Args = {
        {
            Type = "minigame",
            Name = "minigame",
            Description = "The minigame to play",
        },
        {
            Type = "players",
            Name = "players",
            Description = "The players to play the minigame",
        },
        {
            Type = "boolean",
            Name = "multiplayer",
            Description = "Whether or not the passed players should play with others or not",
        },
    },
}
