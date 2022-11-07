local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MinigameConstants = require(ReplicatedStorage.Shared.Minigames.MinigameConstants)

return function()
    local issues: { string } = {}

    -- Minigames should be Enum-like
    for key, value in pairs(MinigameConstants.Minigames) do
        if key ~= value then
            table.insert(issues, ("%s: %s pair inside MinigameConstants.Minigames must be equal"):format(key, value))
        end
    end

    return issues
end
