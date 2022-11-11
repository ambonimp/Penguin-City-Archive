local PetConstants = {}

export type PetEgg = {
    HatchTime: number,
    WeightTable: { {
        Weight: number,
        Value: {
            PetType: string,
            PetVariant: string,
        },
    } },
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
                },
            },
            {
                Weight = 2,
                Value = {
                    PetType = "Dinosaur",
                    PetVariant = "Orange",
                },
            },
            {
                Weight = 3,
                Value = {
                    PetType = "Dinosaur",
                    PetVariant = "Pink",
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
