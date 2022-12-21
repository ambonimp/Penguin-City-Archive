local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestUtil = require(ReplicatedStorage.Shared.Utils.TestUtil)
local SettingsConstants = require(ReplicatedStorage.Shared.Settings.SettingsConstants)

return function()
    local issues: { string } = {}

    -- Volume
    do
        -- Enum-like
        TestUtil.enum(SettingsConstants.Settings.Volume, issues)

        --todo matching soundservice folder
    end

    return issues
end
