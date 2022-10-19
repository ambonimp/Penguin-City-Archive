return {
    Name = "visit",
    Aliases = { "visit" },
    Description = "Teleports a player to another players igloo",
    Group = "|zonesAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to teleport",
        },
        {
            Type = "player",
            Name = "iglooOwner",
            Description = "Igloo Owner",
        },
    },
}
