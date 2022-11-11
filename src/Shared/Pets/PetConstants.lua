local PetConstants = {}

local pets: { [string]: { [string]: string } } = {
    Dinosaur = {
        Green = "Green",
        Orange = "Orange",
        Pink = "Pink",
    },
}
PetConstants.Pets = pets

local animationNames: { [string]: string } = {
    Idle = "Idle",
    Jump = "Jump",
    Sit = "Sit",
    Trick = "Trick",
    Walk = "Walk",
}
PetConstants.AnimationNames = animationNames

return PetConstants
