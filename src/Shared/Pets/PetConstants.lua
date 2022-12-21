local PetConstants = {}

export type PetEgg = {
    WeightTable: { {
        Weight: number,
        Value: PetTuple,
    } },
}

export type PetTuple = {
    PetType: string,
    PetVariant: string,
    PetRarity: string,
}

export type PetData = {
    PetTuple: PetTuple,
    Name: string,
    BirthServerTime: number,
}

local petTypes: { [string]: string } = {
    Dinosaur = "Dinosaur",
    Cat = "Cat",
    Dog = "Dog",
    Panda = "Panda",
    Rabbit = "Rabbit",
    Unicorn = "Unicorn",
}
PetConstants.PetTypes = petTypes

local petVariants: { [string]: { [string]: string } } = {
    [petTypes.Dinosaur] = {
        Green = "Green",
        Orange = "Orange",
        Pink = "Pink",
    },
    [petTypes.Cat] = {
        Black = "Black",
        Blue = "Blue",
        Grey = "Grey",
    },
    [petTypes.Dog] = {
        Black = "Black",
        Brown = "Brown",
        Grey = "Grey",
    },
    [petTypes.Panda] = {
        Black = "Black",
        Blue = "Blue",
        Purple = "Purple",
    },
    [petTypes.Rabbit] = {
        Green = "Green",
        White = "White",
        Yellow = "Yellow",
    },
    [petTypes.Unicorn] = {
        Pink = "Pink",
        Purple = "Purple",
        Yellow = "Yellow",
    },
}
PetConstants.PetVariants = petVariants

local petRarities: { [string]: string } = {
    Starter = "Starter",
    Common = "Common",
    Rare = "Rare",
    Legendary = "Legendary",
}
PetConstants.PetRarities = petRarities

PetConstants.DefaultHatchTime = 20 * 60
PetConstants.PurchasedWithRobuxHatchTime = 0

PetConstants.PetNameCharacterLimit = 20

local petEggs: { [string]: PetEgg } = {
    --#region Starter
    Starter = {
        WeightTable = {
            {
                Weight = 50,
                Value = {
                    PetType = "Dog",
                    PetVariant = "Brown",
                    PetRarity = "Starter",
                },
            },
            {
                Weight = 50,
                Value = {
                    PetType = "Cat",
                    PetVariant = "Grey",
                    PetRarity = "Starter",
                },
            },
        },
    },
    --#endregion
    --#region Common
    Common = {
        WeightTable = {
            {
                Weight = 33,
                Value = {
                    PetType = "Dog",
                    PetVariant = "Brown",
                    PetRarity = "Common",
                },
            },
            {
                Weight = 33,
                Value = {
                    PetType = "Cat",
                    PetVariant = "Grey",
                    PetRarity = "Common",
                },
            },
            {
                Weight = 25,
                Value = {
                    PetType = "Rabbit",
                    PetVariant = "White",
                    PetRarity = "Common",
                },
            },
            {
                Weight = 9,
                Value = {
                    PetType = "Panda",
                    PetVariant = "Black",
                    PetRarity = "Common",
                },
            },
        },
    },
    --#endregion
    --#region Rare
    Rare = {
        WeightTable = {
            {
                Weight = 20,
                Value = {
                    PetType = "Dog",
                    PetVariant = "Brown",
                    PetRarity = "Rare",
                },
            },
            {
                Weight = 40,
                Value = {
                    PetType = "Rabbit",
                    PetVariant = "White",
                    PetRarity = "Rare",
                },
            },
            {
                Weight = 30,
                Value = {
                    PetType = "Panda",
                    PetVariant = "Black",
                    PetRarity = "Rare",
                },
            },
            {
                Weight = 10,
                Value = {
                    PetType = "Dinosaur",
                    PetVariant = "Green",
                    PetRarity = "Rare",
                },
            },
        },
    },
    --#endregion
    --#region Legendary
    Legendary = {
        WeightTable = {
            {
                Weight = 30,
                Value = {
                    PetType = "Rabbit",
                    PetVariant = "White",
                    PetRarity = "Legendary",
                },
            },
            {
                Weight = 40,
                Value = {
                    PetType = "Panda",
                    PetVariant = "Black",
                    PetRarity = "Legendary",
                },
            },
            {
                Weight = 25,
                Value = {
                    PetType = "Dinosaur",
                    PetVariant = "Green",
                    PetRarity = "Legendary",
                },
            },
            {
                Weight = 5,
                Value = {
                    PetType = "Unicorn",
                    PetVariant = "Pink",
                    PetRarity = "Legendary",
                },
            },
        },
    },
    --#endregion
}
PetConstants.PetEggs = petEggs

local animationNames: { [string]: string } = {
    Idle = "Idle",
    Jump = "Jump",
    Sit = "Sit",
    Trick = "Trick",
    Walk = "Walk",
}
PetConstants.AnimationNames = animationNames

PetConstants.PetEggHatchingDuration = 2.5

PetConstants.Following = {
    SideDistance = 5,
    MaxDistance = 10,
    JumpHeight = 2,
    JumpDuration = 1,
}

PetConstants.ModelScale = 0.5

return PetConstants
