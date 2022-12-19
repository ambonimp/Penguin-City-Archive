local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local TestUtil = require(ReplicatedStorage.Shared.Utils.TestUtil)

return function()
    local issues: { string } = {}

    -- ZoneId should be Enum-like
    TestUtil.enum(ZoneConstants.ZoneType.Room, issues)
    TestUtil.enum(ZoneConstants.ZoneType.Minigame, issues)

    -- Must be strings
    for zoneCategory, zoneTypes in pairs(ZoneConstants.ZoneType) do
        for key, value in pairs(zoneTypes) do
            if not tostring(value) == value then
                table.insert(issues, ("%s: %s must be a string!"):format(key, value, zoneCategory))
            end
        end
    end

    -- Travel methods enum
    TestUtil.enum(ZoneConstants.TravelMethod)

    return issues
end
