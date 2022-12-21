local SettingVolumeHandler = {}

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local SettingsController = require(Paths.Client.Settings.SettingsController)

function SettingVolumeHandler.setVolume(groupName: string, volume: number)
    -- ERROR: Bad group name
    local soundFolder = SoundService:FindFirstChild(groupName)
    if not soundFolder then
        error(("Bad sound group name %q"):format(groupName))
    end

    -- ERROR: No sound group?
    local soundGroup = soundFolder:FindFirstChildWhichIsA("SoundGroup")
    if not soundGroup then
        error(("No soundgroup in %s ??"):format(soundFolder:GetFullName()))
    end

    soundGroup.Volume = volume
end

SettingsController.SettingUpdated:Connect(function(settingType: string, settingName: string, settingValue: any)
    if settingType == "Volume" then
        SettingVolumeHandler.setVolume(settingName, settingValue)
    end
end)

return SettingVolumeHandler
