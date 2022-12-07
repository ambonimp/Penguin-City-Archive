local ScreenUtil = {}

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Toggle = require(Paths.Shared.Toggle)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local Binder = require(Paths.Shared.Binder)
local TweenableValue = require(Paths.Shared.TweenableValue)
local CameraController = require(Paths.Client.CameraController)

local BINDING_KEY_OPEN = "ScreenOpenAnimations"
local BINDING_KEY_EXIT = "ScreenExitAnimations"
local ANIMATION_LENGTH = 0.3
local IN_TWEEN_INFO = TweenInfo.new(ANIMATION_LENGTH / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local OUT_TWEEN_INFO = TweenInfo.new(ANIMATION_LENGTH / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
local COSMETICS = {
    BlurSize = 25,
    CameraFOV = 40,
}

local blurSize = TweenableValue.new("IntValue", 0, IN_TWEEN_INFO)
local blurEffect = Instance.new("BlurEffect")
blurEffect.Parent = Lighting
blurSize:BindToProperty(blurEffect, "Size")

-- Whether or not special effects like blackground blur are enabled when a frame is opened
local cosmeticsEnabled = Toggle.new(false, function(value)
    if value then
        blurSize:Set(COSMETICS.BlurSize)
        CameraController.setFov(COSMETICS.CameraFOV, ANIMATION_LENGTH)
    else
        blurSize:Reset()
        CameraController.resetFov(ANIMATION_LENGTH)
    end
end)

local function inn(directionOut: UDim2, frame: GuiObject, cosmetics)
    if cosmetics then
        cosmeticsEnabled:Set(true, frame)
    end

    local initialPosition = Binder.bindFirst(frame, "InitialPosition", frame.Position)

    frame.Visible = false
    frame.Position = directionOut + initialPosition

    frame.Visible = true
    TweenUtil.bind(frame, BINDING_KEY_OPEN, TweenService:Create(frame, IN_TWEEN_INFO, { Position = initialPosition }))
end

local function outt(directionOut: UDim2, frame: GuiObject, cosmetics)
    if cosmetics then
        cosmeticsEnabled:Set(true, frame)
    end

    local initialPosition = Binder.bindFirst(frame, "InitialPosition", frame.Position)

    frame.Visible = true

    TweenUtil.bind(
        frame,
        BINDING_KEY_EXIT,
        TweenService:Create(frame, OUT_TWEEN_INFO, { Position = directionOut + initialPosition }),
        function(playbackState)
            if playbackState == Enum.PlaybackState.Completed then
                frame.Visible = false
            end
        end
    )
end

function ScreenUtil.sizeOut(frame: GuiObject)
    frame.Visible = true
    TweenUtil.bind(frame, BINDING_KEY_OPEN, TweenService:Create(frame, IN_TWEEN_INFO, { Size = UDim2.fromScale(0, 0) }), function()
        frame.Visible = false
    end)
end

function ScreenUtil.sizeIn(frame: GuiObject)
    local MaxSize = frame:GetAttribute("Size") or frame.Size
    if frame:GetAttribute("Size") == nil then
        frame:SetAttribute("Size", frame.Size)
    end
    frame.Size = UDim2.fromScale(0, 0)
    frame.Visible = true
    TweenUtil.bind(frame, BINDING_KEY_OPEN, TweenService:Create(frame, IN_TWEEN_INFO, { Size = MaxSize }))
end

--[[
    Tweens a frame into view from the bottom of the screen to it's initial position
]]
function ScreenUtil.inUp(frame: GuiObject, cosmetics: boolean?)
    inn(UDim2.fromScale(0, 1), frame, cosmetics)
end
--[[
    Tweens a frame out view from the bottom of the screen to it's initial position
]]
function ScreenUtil.outUp(frame: GuiObject, cosmetics: boolean?)
    outt(UDim2.fromScale(0, -1), frame, cosmetics)
end

--[[
    Tweens a frame into view from the top of the screen to it's initial position
]]
function ScreenUtil.inDown(frame: GuiObject, cosmetics: boolean?)
    inn(UDim2.fromScale(0, -1), frame, cosmetics)
end
--[[
    Tweens a frame out of view from the bottom of the screen
]]
function ScreenUtil.outDown(frame: GuiObject, cosmetics: boolean?)
    outt(UDim2.fromScale(0, 1), frame, cosmetics)
end

--[[
    Tweens a frame into view from the left side of the screen to it's initial position
]]
function ScreenUtil.inRight(frame: GuiObject, cosmetics: boolean?)
    inn(UDim2.fromScale(-1, 0), frame, cosmetics)
end

function ScreenUtil.outRight(frame: GuiObject, cosmetics: boolean?)
    outt(UDim2.fromScale(1, 0), frame, cosmetics)
end

--[[
    Tweens a frame into view from the left side of the screen to it's initial position
]]
function ScreenUtil.inLeft(frame: GuiObject, cosmetics: boolean?)
    inn(UDim2.fromScale(1, 0), frame, cosmetics)
end
function ScreenUtil.outLeft(frame: GuiObject, cosmetics: boolean?)
    outt(UDim2.fromScale(-1, 0), frame, cosmetics)
end

function ScreenUtil.out(frame: GuiObject, cosmetics: boolean?)
    frame.Visible = false

    if cosmetics then
        cosmeticsEnabled:Set(false, frame)
    end
end

return ScreenUtil
