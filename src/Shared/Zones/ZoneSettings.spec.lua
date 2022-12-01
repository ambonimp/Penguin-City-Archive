local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local ZoneSettings = require(ReplicatedStorage.Shared.Zones.ZoneSettings)
local Sound = require(ReplicatedStorage.Shared.Sound)

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
