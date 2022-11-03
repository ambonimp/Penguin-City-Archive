return {
    Name = "wipeData",
    Aliases = {},
    Description = "Wipes a player's data",
    Group = "|dataAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to wipe",
        },
        {
            Type = "string",
            Name = "WIPE",
            Description = "Please enter `WIPE` to confirm",
        },
    },
}
