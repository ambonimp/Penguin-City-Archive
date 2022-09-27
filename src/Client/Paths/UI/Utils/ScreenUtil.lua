--[[
    Utility that handles animating frames in and off of screens
]]

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

local BINDING_KEY = "ScreenOpenAnimations"
local ANIMATION_LENGTH = 0.3
local IN_TWEEN_INFO = TweenInfo.new(ANIMATION_LENGTH / 4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
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

local function inn(directionOut: UDim2, frame: Frame, cosmetics)
    if cosmetics then
        cosmeticsEnabled:Set(true, frame)
    end

    local initialPosition = Binder.bindFirst(frame, "InitialPosition", frame.Position)

    frame.Visible = false
    frame.Position = directionOut + initialPosition

    frame.Visible = true
    TweenUtil.bind(frame, BINDING_KEY, TweenService:Create(frame, IN_TWEEN_INFO, { Position = initialPosition }))
end

--[[
    Tweens a frame into view from the bottom of the screen to it's initial position
]]
function ScreenUtil.inUp(frame: Frame, cosmetics: boolean?)
    inn(UDim2.fromScale(0, 1), frame, cosmetics)
end
--[[
    Tweens a frame into view from the top of the screen to it's initial position
]]
function ScreenUtil.inDown(frame: Frame, cosmetics: boolean?)
    inn(UDim2.fromScale(0, -1), frame, cosmetics)
end
--[[
    Tweens a frame into view from the left side of the screen to it's initial position
]]
function ScreenUtil.inRight(frame: Frame, cosmetics: boolean?)
    inn(UDim2.fromScale(-1, 0), frame, cosmetics)
end
--[[
    Tweens a frame into view from the left side of the screen to it's initial position
]]
function ScreenUtil.inLeft(frame: Frame, cosmetics: boolean?)
    inn(UDim2.fromScale(1, 0), frame, cosmetics)
end

function ScreenUtil.out(frame: Frame, cosmetics: boolean?)
    frame.Visible = false

    if cosmetics then
        cosmeticsEnabled:Set(false, frame)
    end
end

return ScreenUtil
