local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterItemConstants = require(ReplicatedStorage.Shared.CharacterItems.CharacterItemConstants)

return function()
    local issues: { string } = {}

    for categoryName, categegoryContants in pairs(CharacterItemConstants) do
        for itemKey, itemConstants in pairs(categegoryContants.Items) do
            -- Name
            if itemConstants.Name then
                if itemConstants.Name ~= itemKey then
                    table.insert(issues, ("%s.%s .Name must match itemKey (%s)"):format(categoryName, itemKey, itemKey))
                end
            else
                table.insert(issues, ("%s.%s has no .Name!"):format(categoryName, itemKey))
            end

            -- Price
            if not itemConstants.Price then
                table.insert(issues, ("%s.%s has no .Price!"):format(categoryName, itemKey))
            end

            if categoryName == "Outfit" then
                for outfitItemType, outfitItems in pairs(itemConstants.Items) do
                    for _, outfitItemKey in pairs(outfitItems) do
                        local outfitItemConstants = CharacterItemConstants[outfitItemType].Items[outfitItemKey]

                        if itemConstants.Price == 0 then
                            if not outfitItemConstants.Price ~= 0 and outfitItemConstants.ForSale then
                                table.insert(
                                    issues,
                                    ("%s outfit item %s must be free since the outfit is free"):format(itemKey, outfitItemKey)
                                )
                            end
                        elseif outfitItemConstants.ForSale then
                            table.insert(
                                issues,
                                ("%s outfit item %s cannot be for up for sale on it's own since it's part of a paid outfit."):format(
                                    itemKey,
                                    outfitItemKey
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
