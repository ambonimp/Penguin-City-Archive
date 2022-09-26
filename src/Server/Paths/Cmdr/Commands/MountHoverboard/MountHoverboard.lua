return {
    Name = "mountHoverboard",
    Aliases = { "mh" },
    Description = "Mounts the passed players to a hoverboard",
    Group = "zAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to mount",
        },
    },
}
