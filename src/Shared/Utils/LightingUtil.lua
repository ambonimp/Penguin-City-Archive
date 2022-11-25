local LightingUtil = {}

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenableValue = require(ReplicatedStorage.Shared.TweenableValue)

local BLUR_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local blur: BlurEffect = Lighting.Blur
local tweenableBlur = TweenableValue.new("NumberValue", blur.Size, BLUR_TWEEN_INFO):BindToProperty(blur, "Size")

function LightingUtil.setBlur(size: number, duration: number?)
    tweenableBlur:Haste(size, duration or BLUR_TWEEN_INFO.Time)
end

function LightingUtil.resetBlur(duration: number?)
    tweenableBlur:HasteReset(duration or BLUR_TWEEN_INFO.Time)
end

return LightingUtil
