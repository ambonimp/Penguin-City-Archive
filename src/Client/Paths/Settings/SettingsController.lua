local SettingsController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Signal = require(Paths.Shared.Signal)
local SettingsConstants = require(Paths.Shared.Settings.SettingsConstants)
local Remotes = require(Paths.Shared.Remotes)
local DataController = require(Paths.Client.DataController)

SettingsController.SettingUpdated = Signal.new() -- { settingType: string, settingName: string, settingValue: any }

local INFORM_OF_INITIAL_SETTINGS_AFTER = 2

local function assertSetting(settingType: string, settingName: string)
    -- RETURN: Bad setting
    if not (SettingsConstants.Settings[settingType] and SettingsConstants.Settings[settingType][settingName]) then
        error(("Bad setting %q %q"):format(settingType, settingName))
    end
end

function SettingsController.getSettingValue(settingType: string, settingName: string)
    assertSetting(settingType, settingName)

    local dataAddress = ("Settings.%s.%s"):format(settingType, settingName)
    return DataController.get(dataAddress) :: any
end

function SettingsController.updateSettingValue(settingType: string, settingName: string, settingValue)
    assertSetting(settingType, settingName)

    -- Inform Client
    SettingsController.SettingUpdated:Fire(settingType, settingName, settingValue)

    -- Inform Server
    Remotes.fireServer("UpdateSettingValue", settingType, settingName, settingValue)
end

function SettingsController.Start()
    -- Init Handlers
    for _, descendant in pairs(Paths.Client.Settings.SettingsHandlers:GetDescendants()) do
        if descendant:IsA("ModuleScript") then
            require(descendant)
        end
    end

    -- Gives time for other scripts to connect to our signal
    task.delay(INFORM_OF_INITIAL_SETTINGS_AFTER, function()
        for settingType, settingNames in pairs(SettingsConstants.Settings) do
            for _, settingName in pairs(settingNames) do
                SettingsController.SettingUpdated:Fire(
                    settingType,
                    settingName,
                    SettingsController.getSettingValue(settingType, settingName)
                )
            end
        end
    end)
end

return SettingsController
