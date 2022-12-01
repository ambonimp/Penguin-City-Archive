local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestUtil = require(ReplicatedStorage.Shared.Utils.TestUtil)
local TutorialConstants = require(ReplicatedStorage.Shared.Tutorial.TutorialConstants)
local FurColorConstants = require(ReplicatedStorage.Shared.Constants.CharacterItems.FurColorConstants)
local CharacterItems = require(ReplicatedStorage.Shared.Constants.CharacterItems)

return function()
    local issues: { string } = {}

    -- Tasks must be Enum
    TestUtil.enum(TutorialConstants.Tasks, issues)

    -- StartingAppearance
    do
        -- Valid Colors
        for _, colorName in pairs(TutorialConstants.StartingAppearance.Colors) do
            if not FurColorConstants.Items[colorName] then
                table.insert(issues, ("StartingAppearance.Colors %q is an invalid color"):format(colorName))
            end
        end

        -- Valid Outfits
        for outfitName, itemsByCategory in pairs(TutorialConstants.StartingAppearance.Outfits) do
            for categoryName, itemNames in pairs(itemsByCategory) do
                local categoryItems = CharacterItems[categoryName]
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
