local PetUtils = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local PetConstants = require(ReplicatedStorage.Shared.Pets.PetConstants)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)

local directory: Folder = ReplicatedStorage.Assets.Pets
local typesFolder: Folder = directory.Types

-------------------------------------------------------------------------------
-- Eggs
-------------------------------------------------------------------------------

function PetUtils.getPetEggDataAddress(petEggName: string)
    return ("Pets.Eggs.%s"):format(petEggName)
end

--[[
    Returns `{ [petEggName]: { [petEggDataIndex]: hatchTime } }` - but taking `playtime` into account!

    - `petEggDataIndex` is what we get from DataUtil.append
]]
function PetUtils.getHatchTimes(hatchTimeByEggsData: { [string]: { [string]: number } }, playtime: number?)
    playtime = playtime or 0

    local cascadedHatchTimes: { [string]: { [string]: number } } = {}
    for petEggName, hatchTimes in pairs(hatchTimeByEggsData) do
        cascadedHatchTimes[petEggName] = {}
        for petEggDataIndex, hatchTime in pairs(hatchTimes) do
            cascadedHatchTimes[petEggName][petEggDataIndex] = math.clamp(hatchTime - playtime, 0, math.huge)
        end
    end

    return cascadedHatchTimes
end

function PetUtils.rollEggForPetTuple(petEggName: string, seed: number?): PetConstants.PetTuple
    local weightTable = PetConstants.PetEggs[petEggName].WeightTable
    return MathUtil.weightedChoice(weightTable, seed and Random.new(seed))
end

-------------------------------------------------------------------------------
-- Pets
-------------------------------------------------------------------------------

function PetUtils.getPetDataAddress(petDataIndex: string)
    return ("Pets.Pets.%s"):format(petDataIndex)
end

function PetUtils.petTuple(petType: string, petVariant: string, petRarity: string)
    PetUtils.verifyPetTuple(petType, petVariant, petRarity)

    local petTuple: PetConstants.PetTuple = {
        PetType = petType,
        PetVariant = petVariant,
        PetRarity = petRarity,
    }
    return petTuple
end

-- Will throw an error is the passed petType / petType&petVariant is bad
function PetUtils.verifyPetTuple(petType: string, petVariant: string?, petRarity: string?)
    local isGood = PetConstants.PetTypes[petType]
            and (petVariant == nil and true or PetConstants.PetVariants[petType][petVariant])
            and (petRarity == nil and true or PetConstants.PetRarities[petRarity])
            and true
        or false
    if not isGood then
        error(("Bad Pet Type/Variant/Rarity %q/%q/%q"):format(tostring(petType), tostring(petVariant), tostring(petRarity)))
    end
end

function PetUtils.getModel(petType: string, petVariant: string): Model
    PetUtils.verifyPetTuple(petType, petVariant)

    return typesFolder[petType].Variants[petVariant]
end

function PetUtils.getAnimations(petType: string)
    PetUtils.verifyPetTuple(petType)

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

function PetUtils.getHeightAlphaFromPetJumpProgress(jumpProgress: number)
    if jumpProgress < 0.5 then
        return TweenService:GetValue(jumpProgress * 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    else
        return TweenService:GetValue(1 - (jumpProgress - 0.5) * 2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    end
end

-------------------------------------------------------------------------------
-- Cmdr
-------------------------------------------------------------------------------

function PetUtils.getPetVariantCmdrArgument(petTypeArgument)
    local petType = petTypeArgument:GetValue()
    return {
        Type = PetUtils.getPetVariantCmdrTypeName(petType),
        Name = "petVariant",
        Description = ("petVariant (%s)"):format(petType),
    }
end

function PetUtils.getPetVariantCmdrTypeName(petType: string)
    return StringUtil.toCamelCase(("%sPetVariant"):format(petType))
end

return PetUtils
