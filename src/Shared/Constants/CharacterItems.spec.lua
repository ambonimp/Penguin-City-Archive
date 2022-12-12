local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterItemConstants = require(ReplicatedStorage.Shared.CharacterItems.CharacterItemConstants)

return function()
    local issues: { string } = {}

    for categoryName, itemConstants in pairs(CharacterItemConstants) do
        for itemKey, item in pairs(itemConstants.Items) do
            -- Name
            if item.Name then
                if item.Name ~= itemKey then
                    table.insert(issues, ("%s.%s .Name must match itemKey (%s)"):format(categoryName, itemKey, itemKey))
                end
            else
                table.insert(issues, ("%s.%s has no .Name!"):format(categoryName, itemKey))
            end

            -- Icon
            if not item.Icon then
                table.insert(issues, ("%s.%s has no .Icon!"):format(categoryName, itemKey))
            end

            -- Price
            if not item.Price then
                table.insert(issues, ("%s.%s has no .Price!"):format(categoryName, itemKey))
            end
        end
    end

    return issues
end
