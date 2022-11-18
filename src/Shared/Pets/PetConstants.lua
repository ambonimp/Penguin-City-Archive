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
    [petTypes.Dinosaur] = {
        Pink = "Pink",
        Purple = "Purple",
        Yellow = "Yellow",
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

PetConstants.PetEggHatchingDuration = 2

PetConstants.Following = {
    SideDistance = 5,
    MaxDistance = 10,
    JumpHeight = 10,
    JumpDuration = 1,
}

PetConstants.ModelScale = 0.4

return PetConstants
