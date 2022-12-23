local TutorialConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterItemConstants = ReplicatedStorage.Shared.CharacterItems.CharacterItemConstants
local ShirtConstants = require(CharacterItemConstants.ShirtConstants)
local PantsConstants = require(CharacterItemConstants.PantsConstants)

TutorialConstants.Tasks = {
    StartingAppearance = "StartingAppearance",
    ContinueTutorial = "ContinueTutorial",
    CustomiseIgloo = "CustomiseIgloo",
    PlayMinigame = "PlayMinigame",
    StarterPetEgg = "StarterPetEgg",
    TutorialCompleted = "TutorialCompleted",
}

TutorialConstants.TaskOrder = {
    TutorialConstants.Tasks.StartingAppearance,
    TutorialConstants.Tasks.ContinueTutorial,
    TutorialConstants.Tasks.CustomiseIgloo,
    TutorialConstants.Tasks.PlayMinigame,
    TutorialConstants.Tasks.StarterPetEgg,
    TutorialConstants.Tasks.TutorialCompleted,
}

TutorialConstants.StartingAppearance = {
    Colors = { "Black", "Red", "Yellow", "Green", "Orange" },
    Outfits = {
        {
            BodyType = { "Kid" },
            Shirt = { ShirtConstants.Items.Classic_Teal_Sweater.Name },
            Pants = { PantsConstants.Items.Blue_Jeans.Name },
        },
        {
            BodyType = { "Kid" },
            Shirt = { ShirtConstants.Items.Classic_Pink_Sweater.Name },
            Pants = { PantsConstants.Items.Pink_Skirt.Name },
        },
        {
            BodyType = { "Adult" },
            Shirt = { ShirtConstants.Items.Red_Lined_Tee.Name },
            Pants = { PantsConstants.Items.Blue_Jeans.Name },
        },
    },
}

TutorialConstants.StarterEgg = {
    PetEggName = "Starter",
    HatchTimeMinutes = 1,
}

return TutorialConstants
