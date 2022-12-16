local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

return {
    --#region Pizza
    {
        Id = "minigame_pizza_play",
        DisplayName = "Chef in Training",
        Description = "Play a round of Pizza Fiasco",
        Type = "Minigame",
        Difficulty = "Easy",
        ImageId = Images.Stamps.Icons.ChefInTraining,
        Metadata = {
            Minigame = "Pizza",
        },
    },
    {
        Id = "minigame_pizza_lose",
        DisplayName = "Fired!",
        Description = "Lose a game of Pizza Fiasco",
        Type = "Minigame",
        Difficulty = "Easy",
        ImageId = Images.Stamps.Icons.Fired,
        Metadata = {
            Minigame = "Pizza",
        },
    },
    {
        Id = "minigame_pizza_correct5",
        DisplayName = "On a Roll!",
        Description = "Make 5 correct pizzas in a row.",
        Type = "Minigame",
        Difficulty = "Easy",
        ImageId = Images.Stamps.Icons.OnARoll,
        Metadata = {
            Minigame = "Pizza",
        },
    },
    {
        Id = "minigame_pizza_extralife",
        DisplayName = "Lucky Find",
        Description = "Collect an Extra Life",
        Type = "Minigame",
        Difficulty = "Medium",
        ImageId = Images.Stamps.Icons.LuckyFind,
        Metadata = {
            Minigame = "Pizza",
        },
    },
    {
        Id = "minigame_pizza_correct25",
        DisplayName = "Line Cook",
        Description = "Make 25 correct pizzas in a row!",
        Type = "Minigame",
        Difficulty = "Medium",
        ImageId = Images.Stamps.Icons.LineCook,
        Metadata = {
            Minigame = "Pizza",
        },
    },
    --#endregion
    --#region Sled
    {
        Id = "minigame_sledrace_wins",
        DisplayName = "Racer",
        IsTiered = true,
        Tiers = {
            Bronze = 1,
            Silver = 10,
            Gold = 25,
        },
        Description = {
            Bronze = "Win 1 round of Sled Racing",
            Silver = "Win 10 rounds of Sled Racing",
            Gold = "Win 25 rounds of Sled Racing",
        },
        Type = "Minigame",
        ImageId = {
            Bronze = Images.Stamps.Icons.Racer_1,
            Silver = Images.Stamps.Icons.Racer_10,
            Gold = Images.Stamps.Icons.Racer_25,
        },
        Metadata = {
            Minigame = "SledRace",
        },
    },
    {
        Id = "minigame_sledrace_obstacle",
        DisplayName = "Look Out!",
        Description = "Hit an obstacle on the Sled Racing minigame.",
        Type = "Minigame",
        Difficulty = "Easy",
        ImageId = Images.Stamps.Icons.LookOut,
        Metadata = {
            Minigame = "SledRace",
        },
    },
    {
        Id = "minigame_sledrace_boost",
        DisplayName = "Weeeee!",
        Description = "Use a speed boost in the Sled Racing minigame.",
        Type = "Minigame",
        Difficulty = "Easy",
        ImageId = Images.Stamps.Icons.Weeeee,
        Metadata = {
            Minigame = "SledRace",
        },
    },
    {
        Id = "minigame_sledrace_winstreak5",
        DisplayName = "Racing Streak",
        Description = "Win 5 rounds of Sled Racing in a row, against atleast one player",
        Type = "Minigame",
        Difficulty = "Hard",
        ImageId = Images.Stamps.Icons.RacingStreak,
        Metadata = {
            Minigame = "SledRace",
        },
    },
    --#endregion
    --#region Icecream
    {
        Id = "minigame_icecream_play",
        DisplayName = "I Scream, You Scream!",
        Description = "Play Ice Cream Extravaganza",
        Type = "Minigame",
        Difficulty = "Easy",
        ImageId = Images.Stamps.Icons.IScreamYouScream,
        Metadata = {
            Minigame = "Icecream",
        },
    },
    {
        Id = "minigame_icecream_collect5",
        DisplayName = "Scoops",
        Description = "Collect 5 scoops of ice cream",
        Type = "Minigame",
        Difficulty = "Easy",
        ImageId = Images.Stamps.Icons.Scoops,
        Metadata = {
            Minigame = "Icecream",
        },
    },
    {
        Id = "minigame_icecream_collect10",
        DisplayName = "Leaning Tower of Ice Cream",
        Description = "Collect 10 scoops of ice cream",
        Type = "Minigame",
        Difficulty = "Medium",
        ImageId = Images.Stamps.Icons.LeaningTowerOfIceCream,
        Metadata = {
            Minigame = "Icecream",
        },
    },
    {
        Id = "minigame_icecream_wins",
        DisplayName = "Icy Winner",
        IsTiered = true,
        Tiers = {
            Bronze = 1,
            Silver = 10,
            Gold = 25,
        },
        Description = {
            Bronze = "Win 1 games of Ice Cream Extravaganza",
            Silver = "Win 10 games of Ice Cream Extravaganza",
            Gold = "Win 25 games of Ice Cream Extravaganza",
        },
        Type = "Minigame",
        ImageId = {
            Bronze = Images.Stamps.Icons.IcyWinner_1,
            Silver = Images.Stamps.Icons.IcyWinner_10,
            Gold = Images.Stamps.Icons.IcyWinner_25,
        },
        Metadata = {
            Minigame = "Icecream",
        },
    },
    --#endregion
}
