local Transitions = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)

local BLINK_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)

local ui = Paths.UI
local specialFx = ui:WaitForChild("SpecialEffects")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

function Transitions.blink(onHalfPoint: (...any) -> nil, alignCamera: boolean?)
    -- Tween In
    do
        local inTween = TweenService:Create(specialFx.Bloom, BLINK_TWEEN_INFO, { BackgroundTransparency = 0 })
        inTween:Play()
        inTween.Completed:Wait()
        inTween:Destroy()
    end

    onHalfPoint()
    if alignCamera then
        camera.CFrame = CFrame.new(camera.CFrame.Position) * player.Character.HumanoidRootPart.CFrame.Rotation
    end

    -- Tween Out
    do
        local outTween = TweenService:Create(specialFx.Bloom, BLINK_TWEEN_INFO, { BackgroundTransparency = 1 })
        outTween:Play()
        outTween.Completed:Wait()
        outTween:Destroy()
    end
end

return Transitions
