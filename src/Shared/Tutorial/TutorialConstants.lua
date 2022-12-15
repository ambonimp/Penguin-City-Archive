local TutorialConstants = {}

TutorialConstants.Tasks = {
    StartingAppearance = "StartingAppearance",
    CustomiseIgloo = "CustomiseIgloo",
    PlayMinigame = "PlayMinigame",
    StarterPetEgg = "StarterPetEgg",
}

TutorialConstants.TaskOrder = {
    TutorialConstants.Tasks.StartingAppearance,
    TutorialConstants.Tasks.CustomiseIgloo,
    TutorialConstants.Tasks.PlayMinigame,
    TutorialConstants.Tasks.StarterPetEgg,
}

TutorialConstants.StartingAppearance = {
    Colors = { "Black", "Red", "Yellow", "Green", "Orange" },
    Outfits = {
        {},
        {
            BodyType = { "Kid" },
            Backpack = { "Brown_Backpack" },
        },
        {
            BodyType = { "Adult" },
            Shirt = { "Flannel_Shirt" },
        },
        {
            BodyType = { "Teen" },
            Hat = { "Backwards_Cap" },
        },
        {
            BodyType = { "Teen" },
            Pants = { "Overalls" },
        },
        {
            BodyType = { "Teen" },
            Shoes = { "Red_Sneakers" },
        },
    },
}

TutorialConstants.StarterEgg = {
    PetEggName = "Common",
    HatchTimeMinutes = 10,
}

return TutorialConstants
