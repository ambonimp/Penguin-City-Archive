local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local ZoneSettings = require(ReplicatedStorage.Shared.Zones.ZoneSettings)

return function()
    local issues: { string } = {}

    -- Have all ZoneCategorys
    for zoneCategory, _ in pairs(ZoneConstants.ZoneCategory) do
        if not ZoneSettings[zoneCategory] then
            table.insert(issues, ("ZoneSettings.%s missing"):format(zoneCategory))
        end
    end
    if #issues > 0 then
        return
    end

    --[[     -- Have good ZoneTypes
    for zoneCategory, _ in pairs(ZoneConstants.ZoneCategory) do
        for zoneType, _ in pairs(ZoneSettings[zoneCategory]) do
            if not ZoneConstants.ZoneType[zoneCategory][zoneType] then
                table.insert(issues, ("ZoneSettings.%s.%s %q is a bad ZoneType"):format(zoneCategory, zoneType, zoneType))
            end
        end
    end *]]

    return issues
end
