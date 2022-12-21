local SettingsController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Signal = require(Paths.Shared.Signal)
local SettingsConstants = require(Paths.Shared.Settings.SettingsConstants)
local Remotes = require(Paths.Shared.Remotes)
local DataController = require(Paths.Client.DataController)
local Limiter = require(Paths.Shared.Limiter)

SettingsController.SettingUpdated = Signal.new() -- { settingType: string, settingName: string, settingValue: any }

local INFORM_OF_INITIAL_SETTINGS_AFTER = 2
local UPDATE_SERVER_AFTER = 1

local function assertSetting(settingType: string, settingName: string)
    -- RETURN: Bad setting
    if not (SettingsConstants.Settings[settingType] and SettingsConstants.Settings[settingType][settingName]) then
        error(("Bad setting %q %q"):format(settingType, settingName))
    end
end

function SettingsController.getSettingValue(settingType: string, settingName: string)
    assertSetting(settingType, settingName)

    local dataAddress = ("Settings.%s.%s"):format(settingType, settingName)
    return DataController.get(dataAddress) or SettingsConstants.Default[settingType]
end

function SettingsController.updateSettingValue(settingType: string, settingName: string, settingValue)
    assertSetting(settingType, settingName)

    -- Inform Client
    SettingsController.SettingUpdated:Fire(settingType, settingName, settingValue)

    -- Inform Server (no spam)
    Limiter.indecisive("SettingsController.updateSettingValue", UPDATE_SERVER_AFTER, function()
        Remotes.fireServer("UpdateSettingValue", settingType, settingName, settingValue)
    end)
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
                local settingValue = SettingsController.getSettingValue(settingType, settingName)
                SettingsController.SettingUpdated:Fire(settingType, settingName, settingValue)
            end
        end
    end)
end

return SettingsController
