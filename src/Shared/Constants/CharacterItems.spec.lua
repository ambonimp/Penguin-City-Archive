local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterItems = require(ReplicatedStorage.Shared.Constants.CharacterItems)

return function()
    local issues: { string } = {}

    for categoryName, itemConstants in pairs(CharacterItems) do
        for itemKey, item in pairs(itemConstants.Items) do
            -- Name
            if not item.Name then
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
