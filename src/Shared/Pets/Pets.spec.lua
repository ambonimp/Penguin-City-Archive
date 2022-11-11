local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetConstants = require(ReplicatedStorage.Shared.Pets.PetConstants)
local PetUtils = require(ReplicatedStorage.Shared.Pets.PetUtils)
local TestUtil = require(ReplicatedStorage.Shared.Utils.TestUtil)

return function()
    local issues: { string } = {}

    -- Verify Pets
    for petType, petVariants in pairs(PetConstants.Pets) do
        -- Enum-Like
        TestUtil.enum(petVariants, issues)

        -- Verify Variants
        for _, petVariant in pairs(petVariants) do
            -- Must have a model
            local success, result = pcall(function()
                return PetUtils.getModel(petType, petVariant)
            end)
            if not success then
                table.insert(issues, ("Missing model for %q %q"):format(petType, petVariant))
            end
        end

        -- Ensure correct animations
        do
            local success, result = pcall(function()
                return PetUtils.getAnimations(petType)
            end)
            if success then
                local animations: typeof(PetUtils.getAnimations()) = result
                for _, animationName in pairs(PetConstants.AnimationNames) do
                    if not animations[animationName] then
                        table.insert(issues, ("%q is missing animation %q"):format(petType, animationName))
                    end
                end
            else
                table.insert(issues, result)
            end
        end
    end

    -- Animations
    TestUtil.enum(PetConstants.AnimationNames)

    return issues
end
