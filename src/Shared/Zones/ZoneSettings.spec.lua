local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local ZoneSettings = require(ReplicatedStorage.Shared.Zones.ZoneSettings)
local Sound = require(ReplicatedStorage.Shared.Sound)

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

    -- Have good Sounds
    do
        for zoneType, zoneSettingsByZoneIds in pairs(ZoneSettings) do
            for zoneId, zoneSettings in pairs(zoneSettingsByZoneIds) do
                -- Music
                if zoneSettings.Music and not Sound.hasSound(zoneSettings.Music) then
                    table.insert(issues, ("ZoneSettings.%s.%s %q is a bad Music name"):format(zoneType, zoneId, zoneSettings.Music))
                end

                -- Ambience
                if zoneSettings.Ambience then
                    for _, ambienceName in pairs(zoneSettings.Ambience) do
                        if not Sound.hasSound(ambienceName) then
                            table.insert(
                                issues,
                                ("ZoneSettings.%s.%s Ambience %q is a bad Ambience name"):format(zoneType, zoneId, ambienceName)
                            )
                        end
                    end
                end
            end
        end
    end

    return issues
end
