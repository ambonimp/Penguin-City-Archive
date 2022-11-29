--[[
    Handles zone music and ambience
]]
local ZoneAudioController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)
local ZoneController = require(Paths.Client.Zones.ZoneController)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local Sound = require(Paths.Shared.Sound)

local FADE_DURATION = 0.5
local DEFAULT_MUSIC_NAME = "MainTheme"

local currentMusic: {
    Sound: Sound?,
    Name: string?,
} = {}

function ZoneAudioController.onZoneUpdate(maid: typeof(Maid.new()), _zoneModel: Model)
    local currentZone = ZoneController.getCurrentZone()
    local zoneSettings = ZoneUtil.getSettings(currentZone)

    -- Music
    local zoneMusicName = (not zoneSettings or zoneSettings.Music == nil) and DEFAULT_MUSIC_NAME or zoneSettings.Music
    if zoneMusicName ~= currentMusic.Name then
        -- Fade Old
        local oldSound = currentMusic.Sound
        if oldSound then
            Sound.fadeOut(oldSound, FADE_DURATION, true)
            currentMusic.Sound = nil
            currentMusic.Name = nil
        end

        -- Create New
        if zoneMusicName then
            local sound = Sound.play(zoneMusicName, true)
            Sound.fadeIn(sound, FADE_DURATION)

            currentMusic.Sound = sound
            currentMusic.Name = zoneMusicName
        end
    end

    -- Ambience
    local ambienceNames = zoneSettings and zoneSettings.Ambience
    if ambienceNames then
        for _, ambienceName in pairs(ambienceNames) do
            local sound = Sound.play(ambienceName, true)
            Sound.fadeIn(sound, FADE_DURATION)
            maid:GiveTask(function()
                Sound.fadeOut(sound, FADE_DURATION, true)
            end)
        end
    end
end

return ZoneAudioController
