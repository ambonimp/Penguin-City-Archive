local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local MinigameConstants = require(ReplicatedStorage.Shared.Minigames.MinigameConstants)
local TestUtil = require(ReplicatedStorage.Shared.Utils.TestUtil)

return function()
    local issues: { string } = {}

    -- ZoneId should be Enum-like
    TestUtil.enum(ZoneConstants.ZoneId.Room, issues)
    TestUtil.enum(ZoneConstants.ZoneId.Minigame, issues)

    -- Must be strings
    for zoneType, zoneIds in pairs(ZoneConstants.ZoneId) do
        for key, value in pairs(zoneIds) do
            if not tostring(value) == value then
                table.insert(issues, ("%s: %s must be a string!"):format(key, value, zoneType))
            end
        end
    end

    -- Minigame ZoneIds should match Minigame Ids
    for _, zoneId in pairs(ZoneConstants.ZoneId.Minigame) do
        if not MinigameConstants.Minigames[zoneId] then
            table.insert(issues, ("Minigame ZoneId %q has no corresponding MinigameConstants.Minigame of the sane name"):format(zoneId))
        end
    end

    -- Cosmetics
    do
        -- Tags must be Enum-Like
        TestUtil.enum(ZoneConstants.Cosmetics.Tags, issues)
    end

    return issues
end
