local Transitions = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)

type BlinkOptions = {
    TweenInfo: TweenInfo?,
    TweenTime: number?, -- Always overrides
    DoAlignCamera: boolean?,
}

Transitions.BLINK_TWEEN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local ui = Paths.UI
local specialFx = ui:WaitForChild("SpecialEffects")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Yields
function Transitions.blink(onHalfPoint: (...any) -> nil, blinkOptions: BlinkOptions?)
    -- Read blink options
    blinkOptions = blinkOptions or {}
    local tweenInfo = blinkOptions.TweenInfo or Transitions.BLINK_TWEEN_INFO
    if blinkOptions.TweenTime then
        tweenInfo = TweenInfo.new(blinkOptions.TweenTime, tweenInfo.EasingStyle, tweenInfo.EasingDirection)
    end
    local doAlignCamera = blinkOptions.DoAlignCamera and true or false

    -- Tween In
    do
        local inTween = TweenService:Create(specialFx.Bloom, tweenInfo, { BackgroundTransparency = 0 })
        inTween:Play()
        inTween.Completed:Wait()
        inTween:Destroy()
    end

    onHalfPoint()
    if doAlignCamera then
        camera.CFrame = CFrame.new(camera.CFrame.Position) * player.Character.HumanoidRootPart.CFrame.Rotation
    end

    -- Tween Out
    do
        local outTween = TweenService:Create(specialFx.Bloom, tweenInfo, { BackgroundTransparency = 1 })
        outTween:Play()
        outTween.Completed:Wait()
        outTween:Destroy()
    end
end

return Transitions
