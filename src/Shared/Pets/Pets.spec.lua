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
            local success, result: Model | string = pcall(function()
                return PetUtils.getModel(petType, petVariant)
            end)
            if success then
                if not result.PrimaryPart then
                    table.insert(issues, ("Pet Model missing Primary Part for %q %q"):format(petType, petVariant))
                end
            else
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

    -- Rarities
    do
        -- Enum
        TestUtil.enum(PetConstants.PetRarities, issues)
    end

    -- Animations
    do
        -- Enum
        TestUtil.enum(PetConstants.AnimationNames, issues)
    end

    -- Pet Eggs
    for petEggName, petEgg in pairs(PetConstants.PetEggs) do
        -- Verify Products
        do
            local success, result = pcall(function()
                return ProductUtil.getPetEggProduct(petEggName)
            end)
            if success then
                -- Needs Model
                local model = ProductUtil.getModel(result)
                if not model then
                    table.insert(issues, ("PetEgg %q Product has no model (%s)"):format(petEggName, result.Id))
                end
            else
                table.insert(issues, ("PetEgg %q has no matching Product (%s)"):format(petEggName, tostring(result)))
            end
        end

        -- Verify Pets
        for i, weightEntry in pairs(petEgg.WeightTable) do
            local success, result = pcall(function()
                PetUtils.verifyPetTuple(
                    weightEntry.Value.PetType or "missing",
                    weightEntry.Value.PetVariant or "missing",
                    weightEntry.Value.PetRarity or "missing"
                )
            end)
            if not success then
                table.insert(issues, ("PetEgg %q has bad weight table entry %d: %s"):format(petEggName, i, tostring(result)))
            end
        end
    end

    return issues
end
