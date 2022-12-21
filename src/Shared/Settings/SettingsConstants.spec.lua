local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestUtil = require(ReplicatedStorage.Shared.Utils.TestUtil)
local SettingsConstants = require(ReplicatedStorage.Shared.Settings.SettingsConstants)

return function()
    local issues: { string } = {}

    for settingType, settingNames in pairs(SettingsConstants.Settings) do
        -- Enum-like names
        TestUtil.enum(settingNames, issues)

        -- Default value
        if not SettingsConstants.Default[settingType] then
            table.insert(issues, (("Missing default value for setting type %q"):format(settingType)))
        end
    end

    return issues
end
