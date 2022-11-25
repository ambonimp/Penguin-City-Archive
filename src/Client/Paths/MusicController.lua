--[[
    Plays music based on the zone we're in
]]
local MusicController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local ZoneController = require(Paths.Client.ZoneController)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local Sound = require(Paths.Shared.Sound)

local FADE_DURATION = 0.5
local DEFAULT_MUSIC_NAME = "MainTheme"

local currentMusic: {
    Sound: Sound?,
    Name: string?,
} = {}

local function onZoneUpdate(_fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone, playNewZone: boolean)
    -- Get music track name
    local settings = ZoneUtil.getSettings(toZone)
    local isDisabled = settings and settings.Music == false
    local zoneMusic: string?
    if not isDisabled then
        zoneMusic = settings and settings.Music or DEFAULT_MUSIC_NAME
    end

    -- RETURN: Same track
    if currentMusic.Name == zoneMusic then
        return
    end

    -- Fade old sound
    if currentMusic.Sound then
        Sound.fadeOut(currentMusic.Sound, FADE_DURATION, true)
        currentMusic.Sound = nil
    end

    -- RETURN: Music disabled
    if isDisabled or not playNewZone then
        currentMusic.Name = nil
        return
    end

    -- Fade new sound
    currentMusic.Name = zoneMusic
    currentMusic.Sound = Sound.play(currentMusic.Name, true)
    Sound.fadeIn(currentMusic.Sound, FADE_DURATION)
end

ZoneController.ZoneChanged:Connect(function(fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone)
    onZoneUpdate(fromZone, toZone, true)
end)
ZoneController.ZoneChanging:Connect(function(fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone)
    onZoneUpdate(fromZone, toZone, false)
end)
onZoneUpdate(ZoneUtil.defaultZone(), ZoneUtil.defaultZone(), true)

return MusicController
