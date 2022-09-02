local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Transitions = {}

local Paths = require(script.Parent.Parent.Parent)

local ui = Paths.UI
local specialFx = ui:WaitForChild("SpecialEffects")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

function Transitions.blink(onHalfPoint, alignCamera)
    local info = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)

    local inTween = TweenService:Create(specialFx.Bloom, info, {BackgroundTransparency = 0})
    inTween:Play()
    inTween.Completed:Wait()

    onHalfPoint()
    if alignCamera then
        camera.CFrame = CFrame.new(camera.CFrame.Position) * player.Character.HumanoidRootPart.CFrame.Rotation
    end

    local outTween = TweenService:Create(specialFx.Bloom, info, {BackgroundTransparency = 1})
    outTween:Play()
    outTween.Completed:Wait()

end

return Transitions