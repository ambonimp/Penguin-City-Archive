local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

return {
    {
        Id = "events_alpha",
        DisplayName = "Alpha Tester",
        Description = ("Play %s in Alpha"):format(GameConstants.PrettyGameName),
        Type = "Events",
        Difficulty = "???",
        ImageId = "",
        Metadata = {
            Event = "Alpha",
        },
    },
    {
        Id = "events_playtime_payday",
        DisplayName = "Payday!",
        Description = "Collect your first paycheck.",
        Type = "Events",
        Difficulty = "Easy",
        ImageId = "",
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
        ImageId = "",
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
        ImageId = "",
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
        ImageId = "",
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
        ImageId = "",
        Metadata = {
            Event = "Playtime_Rewards",
        },
    },
}
