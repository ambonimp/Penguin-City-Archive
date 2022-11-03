local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

return {
    {
        Id = "igloo_getting_started",
        DisplayName = "Getting Started",
        Description = "Place your first piece of furniture!",
        Type = "Igloo",
        Difficulty = "Easy",
        ImageId = Images.Stamps.Icons.GettingStarted,
    },
    {
        Id = "igloo_thats_better",
        DisplayName = "That's Better",
        Description = "Color your first piece of furniture!",
        Type = "Igloo",
        Difficulty = "Easy",
        ImageId = Images.Stamps.Icons.ThatsBetter,
    },
    {
        Id = "igloo_sleepover",
        DisplayName = "Sleepover",
        Description = "Visit another player's igloo",
        Type = "Igloo",
        Difficulty = "Easy",
        ImageId = Images.Stamps.Icons.Sleepover,
    },
    {
        Id = "igloo_critic",
        DisplayName = "Igloo Critic",
        Description = "Heart 15 Houses",
        Type = "Igloo",
        Difficulty = "Medium",
        ImageId = Images.Stamps.Icons.IglooCritic,
    },
    {
        Id = "igloo_decorator",
        DisplayName = "Interior Decorator",
        Description = "Place 25 items in your igloo",
        Type = "Igloo",
        Difficulty = "Medium",
        ImageId = Images.Stamps.Icons.InteriorDecorator,
    },
    {
        Id = "igloo_party",
        DisplayName = "Party in my Iggy!",
        Description = "Host an Igloo Party.",
        Type = "Igloo",
        Difficulty = "Medium",
        ImageId = Images.Stamps.Icons.PartyInMyIggy,
    },
    {
        Id = "igloo_best_house",
        DisplayName = "Best House on the Block",
        IsTiered = true,
        Description = {
            Bronze = "Get 50 hearts on your igloo",
            Silver = "Get 100 hearts on your igloo",
            Gold = "Get 200 hearts on your igloo",
        },
        Type = "Igloo",
        ImageId = {
            Bronze = Images.Stamps.Icons.BestHouseOnTheBlock_50,
            Silver = Images.Stamps.Icons.BestHouseOnTheBlock_100,
            Gold = Images.Stamps.Icons.BestHouseOnTheBlock_200,
        },
    },
}
