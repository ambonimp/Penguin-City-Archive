local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterItemConstants = require(ReplicatedStorage.Shared.CharacterItems.CharacterItemConstants)

return function()
    local issues: { string } = {}

    for categoryName, categegoryContants in pairs(CharacterItemConstants) do
        for itemName, itemConstants in pairs(categegoryContants.Items) do
            -- Name
            if itemConstants.Name then
                if itemConstants.Name ~= itemName then
                    table.insert(issues, ("%s.%s .Name must match itemName (%s)"):format(categoryName, itemName, itemName))
                end
            else
                table.insert(issues, ("%s.%s has no .Name!"):format(categoryName, itemName))
            end

            -- Icon
            if not itemConstants.Icon then
                table.insert(issues, ("%s.%s has no icon!"):format(categoryName, itemName))
            end

            -- Price
            if not itemConstants.Price then
                table.insert(issues, ("%s.%s has no .Price!"):format(categoryName, itemName))
            end

            if categoryName == "Outfit" then
                for outfitItemType, outfitItems in pairs(itemConstants.Items) do
                    for _, outfitItemName in pairs(outfitItems) do
                        local outfitItemConstants = CharacterItemConstants[outfitItemType].Items[outfitItemName]

                        if itemConstants.Price == 0 then
                            if not outfitItemConstants.Price ~= 0 and outfitItemConstants.ForSale then
                                table.insert(
                                    issues,
                                    ("%s outfit item %s must be free since the outfit is free"):format(itemName, outfitItemName)
                                )
                            end
                        elseif outfitItemConstants.ForSale then
                            table.insert(
                                issues,
                                ("%s outfit item %s cannot be for up for sale on it's own since it's part of a paid outfit."):format(
                                    itemName,
                                    outfitItemName
                                )
                            )
                        end
                    end
                end
            end
        end
    end

    return issues
end
