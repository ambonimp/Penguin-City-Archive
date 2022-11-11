local PetUtils = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetConstants = require(ReplicatedStorage.Shared.Pets.PetConstants)

local directory: Folder = ReplicatedStorage.Assets.Pets

-- Will throw an error is the passed petType / petType&petVariant is bad
function PetUtils.verifyPetTypeVariant(petType: string, petVariant: string?)
    local isGood = PetConstants.Pets[petType] and (petVariant == nil and true or PetConstants.Pets[petType][petVariant]) and true or false
    if not isGood then
        error(("Bad Pet Type/Variant %q/%q"):format(petType, petVariant))
    end
end

function PetUtils.getModel(petType: string, petVariant: string): Model
    PetUtils.verifyPetTypeVariant(petType, petVariant)

    return directory[petType].Variants[petVariant]
end

function PetUtils.getAnimations(petType: string)
    PetUtils.verifyPetTypeVariant(petType)

    local animationController = directory[petType]:FindFirstChildOfClass("AnimationController")
    if not animationController then
        error(("No AnimationController for PetType %q"):format(petType))
    end

    local animations: { [string]: Animation } = {}
    for _, animationName in pairs(PetConstants.AnimationNames) do
        animations[animationName] = animationController:FindFirstChild(animationName)
    end

    return animations
end

return PetUtils
