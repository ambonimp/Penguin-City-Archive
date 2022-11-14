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

--[[
    Returns `{ [petEggName]: { hatchTime } }`
]]
function PetUtils.getHatchTimes(hatchTimeByEggsData: { [string]: { [string]: number } }, playtime: number?)
    playtime = playtime or 0

    local allHatchTimes: { [string]: { number } } = {}
    for petEggName, _petEgg in pairs(PetConstants.PetEggs) do
        local hatchTimes: { number } = hatchTimeByEggsData[petEggName] and TableUtil.toArray(hatchTimeByEggsData[petEggName])
        if hatchTimes then
            hatchTimes = TableUtil.mapValues(hatchTimes, function(hatchTime: number)
                return math.clamp(hatchTime - playtime, 0, math.huge)
            end)
            allHatchTimes[petEggName] = hatchTimes
        end
    end

    return allHatchTimes
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
