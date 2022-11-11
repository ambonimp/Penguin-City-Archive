local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

return {
    {
        Id = "events_playtime_payday",
        DisplayName = "Payday!",
        Description = "Collect your first paycheck.",
        Type = "Events",
        Difficulty = "Easy",
        ImageId = Images.Stamps.Icons.Payday,
        Metadata = {
            Event = "Playtime_Rewards",
        },
    },
    {
        Id = "events_playtime_collect5",
        DisplayName = "Making Money!",
        Description = "Collect 5 Paychecks!",
        Type = "Events",
        Difficulty = "Easy",
        ImageId = Images.Stamps.Icons.MakingMoney,
        Metadata = {
            Event = "Playtime_Rewards",
        },
    },
    {
        Id = "events_playtime_streak1",
        DisplayName = "Welcome Back!",
        Description = "Get a 1 day streak!",
        Type = "Events",
        Difficulty = "Easy",
        ImageId = Images.Stamps.Icons.WelcomeBack,
        Metadata = {
            Event = "Playtime_Rewards",
        },
    },
    {
        Id = "events_playtime_mins20",
        DisplayName = "Official Citizen",
        Description = "Play for 20 consecutive minutes",
        Type = "Events",
        Difficulty = "Easy",
        ImageId = Images.Stamps.Icons.OfficialCitizen,
        Metadata = {
            Event = "Playtime_Rewards",
        },
    },
    {
        Id = "events_playtime_day30",
        DisplayName = "One Month In",
        Description = "Get a 30 Day Streak",
        Type = "Events",
        Difficulty = "Hard",
        ImageId = Images.Stamps.Icons.OneMonthIn,
        Metadata = {
            Event = "Playtime_Rewards",
        },
    },
}
