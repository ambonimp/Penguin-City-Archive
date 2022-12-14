local MapScreen = {}

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local Button = require(Paths.Client.UI.Elements.Button)
local Images = require(Paths.Shared.Images.Images)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ZoneController = require(Paths.Client.Zones.ZoneController)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local Loader = require(Paths.Client.Loader)
local TableUtil = require(Paths.Shared.Utils.TableUtil)

local REMOVE_STATE_AFTER = 0.5
local BACKGROUND_FADE_TWEEN_INFO = TweenInfo.new(0.3)

local ZONES = {
    Boardwalk = "Boardwalk",
    School = "School",
    Neighborhood = "Neighborhood",
    SkiHill = "Ski Hill",
    Town = "Town",
} -- Keys are ZoneTypes, values are display names

local screenGui: ScreenGui = Ui.Map
local closeButtonFrame: Frame = screenGui.CloseButton
local backgroundFrame: ImageLabel = screenGui.Background
local mapFrame: ImageLabel = screenGui.Map
local zoneImageLabel: ImageLabel = mapFrame.Zone
local pinsFrame: Frame = screenGui.Pins

local closeButton = ExitButton.new(UIConstants.States.Map)

function MapScreen.Init()
    -- Buttons
    do
        closeButton:Mount(closeButtonFrame, true)
        closeButton.Pressed:Connect(function()
            UIController.getStateMachine():Remove(UIConstants.States.Map)
        end)
    end

    -- Populate Pins
    do
        local pinTemplate: ImageButton = pinsFrame.pinTemplate
        for zoneType, zoneDisplayName in pairs(ZONES) do
            -- ERROR: No pin position frame
            local pinPositionFrame: Frame = pinsFrame:FindFirstChild(zoneType)
            if not pinPositionFrame then
                error(("Could not find pin position frame %q in %s"):format(zoneType, pinPositionFrame:GetFullName()))
            end

            -- ERROR: No image
            local zoneImage = Images.Map.Zones[zoneType]
            if not zoneImage then
                error(("No map zone image %q"):format(zoneType))
            end

            -- ERROR: Bad zone!
            local zone = ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, zoneType)
            if not ZoneUtil.doesZoneExist(zone) then
                error(("Bad zoneType %q; zone does not exist!"):format(zoneType))
            end

            local pin = pinTemplate:Clone()
            pin.Visible = true
            pin.ZoneLabel.TextLabel.Text = zoneDisplayName
            pin.Position = pinPositionFrame.Position
            pin.Name = zoneType
            pin.Parent = pinsFrame

            pinPositionFrame:Destroy()

            local pinButton = Button.new(pin)
            pinButton.InternalEnter:Connect(function()
                zoneImageLabel.Image = zoneImage
            end)
            pinButton.InternalLeave:Connect(function()
                if zoneImageLabel.Image == zoneImage then
                    zoneImageLabel.Image = ""
                end
            end)
            pinButton.Pressed:Connect(function()
                task.delay(REMOVE_STATE_AFTER, function()
                    UIController.getStateMachine():Remove(UIConstants.States.Map)
                end)
                ZoneController.teleportToRoomRequest(zone, true)
            end)
        end

        pinTemplate.Visible = false
    end

    -- Register UIState
    UIController.registerStateScreenCallbacks(UIConstants.States.Map, {
        Boot = MapScreen.boot,
        Shutdown = MapScreen.shutdown,
        Maximize = MapScreen.maximize,
        Minimize = MapScreen.minimize,
    })

    -- Init
    InstanceUtil.hide(backgroundFrame)
end

function MapScreen.maximize()
    zoneImageLabel.Image = ""

    ScreenUtil.inLeft(closeButtonFrame)
    ScreenUtil.inDown(mapFrame)
    ScreenUtil.inUp(pinsFrame)
    InstanceUtil.show(backgroundFrame, BACKGROUND_FADE_TWEEN_INFO)
    screenGui.Enabled = true
end

function MapScreen.minimize()
    ScreenUtil.outRight(closeButtonFrame)
    ScreenUtil.outUp(mapFrame)
    ScreenUtil.outDown(pinsFrame)
    InstanceUtil.hide(backgroundFrame, BACKGROUND_FADE_TWEEN_INFO)
end

-- Load images
Loader.giveTask("Map", "Images", function()
    ContentProvider:PreloadAsync(TableUtil.toArray(Images.Map.Zones))
end)

return MapScreen
