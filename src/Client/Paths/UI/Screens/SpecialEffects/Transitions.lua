local Transitions = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local CameraController = require(Paths.Client.CameraController)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)

export type BlinkOptions = {
    TweenInfo: TweenInfo?,
    TweenTime: number?, -- Always overrides
    DoAlignCamera: boolean?,
}

local BLINK_BINDING_KEY = "Blink"

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local ui = Paths.UI
local specialFx = ui:WaitForChild("SpecialEffects")

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
Transitions.BLINK_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function getBlinkTweenInfo(blinkOptions: BlinkOptions?)
    -- Read blink options
    blinkOptions = blinkOptions or {}
    local tweenInfo = blinkOptions.TweenInfo or Transitions.BLINK_TWEEN_INFO
    if blinkOptions.TweenTime then
        tweenInfo = TweenInfo.new(blinkOptions.TweenTime, tweenInfo.EasingStyle, tweenInfo.EasingDirection)
    end

    return tweenInfo
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function Transitions.openBlink(blinkOptions: BlinkOptions?)
    local inTween = TweenUtil.bind(
        specialFx.Bloom,
        BLINK_BINDING_KEY,
        TweenService:Create(specialFx.Bloom, getBlinkTweenInfo(blinkOptions), { BackgroundTransparency = 0 })
    )
    inTween.Completed:Wait()
end

function Transitions.closeBlink(blinkOptions: BlinkOptions?)
    -- RETURN: Blink is already closed
    if specialFx.Bloom.BackgroundTransparency == 1 then
        return
    end

    local inTween = TweenUtil.bind(
        specialFx.Bloom,
        BLINK_BINDING_KEY,
        TweenService:Create(specialFx.Bloom, getBlinkTweenInfo(blinkOptions), { BackgroundTransparency = 1 })
    )
    inTween.Completed:Wait()
end

-- Yields
function Transitions.blink(onHalfPoint: (...any) -> nil, blinkOptions: BlinkOptions?)
    blinkOptions = blinkOptions or {}
    local doAlignCamera = blinkOptions.DoAlignCamera and true or false

    Transitions.openBlink(blinkOptions)

    onHalfPoint()
    if doAlignCamera then
        CameraController.alignCharacter()
    end

    -- Tween Out
    Transitions.closeBlink(blinkOptions)
end

return Transitions
