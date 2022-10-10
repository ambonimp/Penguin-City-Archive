local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local ZoneSettings = require(ReplicatedStorage.Shared.Zones.ZoneSettings)

return function()
    local issues: { string } = {}

    -- Have all ZoneTypes
    for zoneType, _ in pairs(ZoneConstants.ZoneType) do
        if not ZoneSettings[zoneType] then
            table.insert(issues, ("ZoneSettings.%s missing"):format(zoneType))
        end
    end
    if #issues > 0 then
        return
    end

    -- Have good ZoneIds
    for zoneType, _ in pairs(ZoneConstants.ZoneType) do
        for zoneId, _ in pairs(ZoneSettings[zoneType]) do
            if not ZoneConstants.ZoneId[zoneType][zoneId] then
                table.insert(issues, ("ZoneSettings.%s.%s %q is a bad ZoneId"):format(zoneType, zoneId, zoneId))
            end
        end
    end

    return issues
end
