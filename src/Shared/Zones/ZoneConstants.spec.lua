local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local MinigameConstants = require(ReplicatedStorage.Shared.Minigames.MinigameConstants)

return function()
    local issues: { string } = {}

    -- ZoneId should be Enum-like + non-numeric
    for zoneType, zoneIds in pairs(ZoneConstants.ZoneId) do
        for key, value in pairs(zoneIds) do
            if key ~= value then
                table.insert(issues, ("%s: %s pair inside ZoneConstants.ZoneId.%s must be equal"):format(key, value, zoneType))
            end
            if tonumber(value) then
                table.insert(issues, ("%s: %s cannot be numeric!"):format(key, value, zoneType))
            end
        end
    end

    -- Minigame ZoneIds should match Minigame Ids
    for _, zoneId in pairs(ZoneConstants.ZoneId.Minigame) do
        if not MinigameConstants.Minigames[zoneId] then
            table.insert(issues, ("Minigame ZoneId %q has no corresponding MinigameConstants.Minigame of the sane name"):format(zoneId))
        end
    end

    return issues
end
