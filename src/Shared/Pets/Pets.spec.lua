local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetConstants = require(ReplicatedStorage.Shared.Pets.PetConstants)
local PetUtils = require(ReplicatedStorage.Shared.Pets.PetUtils)
local TestUtil = require(ReplicatedStorage.Shared.Utils.TestUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local ProductUtil = require(ReplicatedStorage.Shared.Products.ProductUtil)

return function()
    local issues: { string } = {}

    -- PetTypes
    do
        -- Enum
        TestUtil.enum(PetConstants.PetTypes, issues)

        -- All Used
        if TableUtil.length(PetConstants.PetTypes) ~= TableUtil.length(PetConstants.PetVariants) then
            table.insert(issues, "There is a mismatch between the total PetTypes registered, and entries in PetVariants")
        end
    end

    -- PetType/PetVariants
    for petType, petVariants in pairs(PetConstants.PetVariants) do
        -- Enum
        TestUtil.enum(petVariants, issues)

        -- Good PetType
        if not PetConstants.PetTypes[petType] then
            table.insert(issues, ("Bad PetType %q in PetVariants"):format(petType))
        end

        -- Models
        for _, petVariant in pairs(petVariants) do
            -- Must have a model
            local success, result = pcall(function()
                return PetUtils.getModel(petType, petVariant)
            end)
            if not success then
                table.insert(issues, ("Missing model for %q %q (%s)"):format(petType, petVariant, tostring(result)))
            end
        end

        -- Ensure correct animations
        do
            local success, result = pcall(function()
                return PetUtils.getAnimations(petType)
            end)
            if success then
                local animations: typeof(PetUtils.getAnimations("")) = result
                for _, animationName in pairs(PetConstants.AnimationNames) do
                    if not animations[animationName] then
                        table.insert(issues, ("%q is missing animation %q"):format(petType, animationName))
                    end
                end
            else
                table.insert(issues, tostring(result))
            end
        end
    end

    -- Animations
    do
        -- Enum
        TestUtil.enum(PetConstants.AnimationNames)
    end

    -- Pet Eggs
    for petEggName, petEgg in pairs(PetConstants.PetEggs) do
        -- Verify Products
        do
            local success, result = pcall(function()
                return ProductUtil.getPetEggProduct(petEggName, "Incubating") and ProductUtil.getPetEggProduct(petEggName, "Ready")
            end)
            if not success then
                table.insert(issues, ("PetEgg %q has no matching Product (%s)"):format(petEggName, tostring(result)))
            end
        end

        -- Verify Pets
        for i, weightEntry in pairs(petEgg.WeightTable) do
            local success, result = pcall(function()
                PetUtils.verifyPetTypeVariant(weightEntry.Value.PetType, weightEntry.Value.PetVariant)
            end)
            if not success then
                table.insert(issues, ("PetEgg %q has bad weight table entry %d: %s"):format(petEggName, i, tostring(result)))
            end
        end
    end

    return issues
end
