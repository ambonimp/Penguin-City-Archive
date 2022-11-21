local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local MinigameConstants = require(ReplicatedStorage.Shared.Minigames.MinigameConstants)

return function()
    local issues: { string } = {}

    -- ZoneType should be Enum-like + non-numeric
    for zoneCategory, zoneTypes in pairs(ZoneConstants.ZoneType) do
        for key, value in pairs(zoneTypes) do
            if key ~= value then
                table.insert(issues, ("%s: %s pair inside ZoneConstants.ZoneType.%s must be equal"):format(key, value, zoneCategory))
            end
            if tonumber(value) then
                table.insert(issues, ("%s: %s cannot be numeric!"):format(key, value, zoneCategory))
            end
        end
    end

    -- Minigame ZoneTypes should match Minigame Ids
    for _, zoneType in pairs(ZoneConstants.ZoneType.Minigame) do
        if not MinigameConstants.Minigames[zoneType] then
            table.insert(issues, ("Minigame ZoneType %q has no corresponding MinigameConstants.Minigame of the sane name"):format(zoneType))
        end
    end

    return issues
end
