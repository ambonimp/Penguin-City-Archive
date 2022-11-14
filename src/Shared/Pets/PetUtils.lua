local PetUtils = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetConstants = require(ReplicatedStorage.Shared.Pets.PetConstants)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local directory: Folder = ReplicatedStorage.Assets.Pets
local typesFolder: Folder = directory.Types
local eggsFolder: Folder = directory.Eggs

-------------------------------------------------------------------------------
-- Eggs
-------------------------------------------------------------------------------

function PetUtils.getPetEggDataAddress(petEggName: string)
    return ("Pets.Eggs.%s"):format(petEggName)
end

--[[
    Returns `{ [petEggName]: { [petEggIndex]: hatchTime } }` - but taking `playtime` into account!
]]
function PetUtils.getHatchTimes(hatchTimeByEggsData: { [string]: { [string]: number } }, playtime: number?)
    playtime = playtime or 0

    local cascadedHatchTimes: { [string]: { [string]: number } } = {}
    for petEggName, hatchTimes in pairs(hatchTimeByEggsData) do
        cascadedHatchTimes[petEggName] = {}
        for petEggIndex, hatchTime in pairs(hatchTimes) do
            cascadedHatchTimes[petEggName][petEggIndex] = math.clamp(hatchTime - playtime, 0, math.huge)
        end
    end

    return cascadedHatchTimes
end

-------------------------------------------------------------------------------
-- Pets
-------------------------------------------------------------------------------

-- Will throw an error is the passed petType / petType&petVariant is bad
function PetUtils.verifyPetTypeVariant(petType: string, petVariant: string?)
    local isGood = PetConstants.PetTypes[petType] and (petVariant == nil and true or PetConstants.PetVariants[petType][petVariant]) and true
        or false
    if not isGood then
        error(("Bad Pet Type/Variant %q/%q"):format(petType, petVariant))
    end
end

function PetUtils.getModel(petType: string, petVariant: string): Model
    PetUtils.verifyPetTypeVariant(petType, petVariant)

    return typesFolder[petType].Variants[petVariant]
end

function PetUtils.getAnimations(petType: string)
    PetUtils.verifyPetTypeVariant(petType)

    local animationController = directory.Types[petType]:FindFirstChildOfClass("AnimationController")
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
