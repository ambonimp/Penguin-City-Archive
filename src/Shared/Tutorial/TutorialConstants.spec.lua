local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestUtil = require(ReplicatedStorage.Shared.Utils.TestUtil)
local TutorialConstants = require(ReplicatedStorage.Shared.Tutorial.TutorialConstants)
local CharacterItemConstants = require(ReplicatedStorage.Shared.CharacterItems.CharacterItemConstants)

return function()
    local issues: { string } = {}

    -- Tasks must be Enum
    TestUtil.enum(TutorialConstants.Tasks, issues)

    -- StartingAppearance
    do
        -- Valid Colors
        for _, colorName in pairs(TutorialConstants.StartingAppearance.Colors) do
            if not CharacterItemConstants.FurColor.Items[colorName] then
                table.insert(issues, ("StartingAppearance.Colors %q is an invalid color"):format(colorName))
            end
        end

        -- Valid Outfits
        for outfitName, itemsByCategory in pairs(TutorialConstants.StartingAppearance.Outfits) do
            for categoryName, itemNames in pairs(itemsByCategory) do
                local categoryItems = CharacterItemConstants[categoryName]
                if categoryItems then
                    for _, itemName in pairs(itemNames) do
                        if not categoryItems.Items[itemName] then
                            table.insert(
                                issues,
                                ("StartingAppearance.Outfits.%s.%s bad item name %q"):format(outfitName, categoryName, itemName)
                            )
                        end
                    end
                else
                    table.insert(issues, ("StartingAppearance.Outfits.%s bad category name %q"):format(outfitName, categoryName))
                end
            end
        end
    end

    return issues
end
