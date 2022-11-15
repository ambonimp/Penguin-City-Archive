local PetConstants = {}

export type PetEgg = {
    HatchTime: number,
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

local petTypes: { [string]: string } = {
    Dinosaur = "Dinosaur",
}
PetConstants.PetTypes = petTypes

local petVariants: { [string]: { [string]: string } } = {
    [petTypes.Dinosaur] = {
        Green = "Green",
        Orange = "Orange",
        Pink = "Pink",
    },
}
PetConstants.PetVariants = petVariants

local petRarities: { [string]: string } = {
    Common = "Common",
    Rare = "Rare",
    Legendary = "Legendary",
}
PetConstants.PetRarities = petRarities

PetConstants.DefaultHatchTime = 20 * 60

local petEggs: { [string]: PetEgg } = {
    Test = {
        HatchTime = PetConstants.DefaultHatchTime,
        WeightTable = {
            {
                Weight = 1,
                Value = {
                    PetType = "Dinosaur",
                    PetVariant = "Green",
                    PetRarity = "Common",
                },
            },
            {
                Weight = 2,
                Value = {
                    PetType = "Dinosaur",
                    PetVariant = "Orange",
                    PetRarity = "Common",
                },
            },
            {
                Weight = 3,
                Value = {
                    PetType = "Dinosaur",
                    PetVariant = "Pink",
                    PetRarity = "Common",
                },
            },
        },
    },
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

return PetConstants
