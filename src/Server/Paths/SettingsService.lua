local SettingsService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local DataService = require(Paths.Server.Data.DataService)
local SettingsConstants = require(Paths.Shared.Settings.SettingsConstants)
local Remotes = require(Paths.Shared.Remotes)
local TypeUtil = require(Paths.Shared.Utils.TypeUtil)

local DEFAULT_VOLUME = 0.5

Remotes.bindEvents({
    UpdateSettingValue = function(player: Player, dirtySettingType: any, dirtySettingName: any, dirtySettingValue: any)
        -- Clean type/name
        local settingType = TypeUtil.toString(dirtySettingType)
        local settingName = TypeUtil.toString(dirtySettingName)
        if not (settingType and settingName) then
            return
        end

        -- Volume
        if settingType == "Volume" then
            -- WARN: Bad settingName
            if not SettingsConstants.Settings.Volume[settingName] then
                warn(("Bad volume %q"):format(settingName))
                return
            end

            local volumeValue = math.clamp(TypeUtil.toNumber(dirtySettingValue, DEFAULT_VOLUME), 0, 1)
            local dataAddress = ("Settings.Volume.%s"):format(settingName)

            DataService.set(player, dataAddress, volumeValue)

            return
        end

        warn(("Don't know how to handle settingtype %q"):format(settingType))
    end,
})

return SettingsService
