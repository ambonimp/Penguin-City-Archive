local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)

return function()
    local issues: { string } = {}

    -- ZoneId should be Enum-like
    for zoneType, zoneIds in pairs(ZoneConstants.ZoneId) do
        for key, value in pairs(zoneIds) do
            if key ~= value then
                table.insert(issues, ("%s: %s pair inside ZoneConstants.ZoneId.%s must be equal"):format(key, value, zoneType))
            end
        end
    end

    return issues
end
