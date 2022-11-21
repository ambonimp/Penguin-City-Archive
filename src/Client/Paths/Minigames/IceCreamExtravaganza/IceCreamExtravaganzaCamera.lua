local IceCreamExtravaganzaCamera = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Shake = require(Paths.Shared.Shake)

local camera = Workspace.CurrentCamera
local shake = Shake.new(8, 0.8, 0.5, 5, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out))

function IceCreamExtravaganzaCamera.setup()
    -- Shake
    shake:Reset()
    RunService:BindToRenderStep("CameraShake", Enum.RenderPriority.Camera.Value + 1, function(dt)
        camera.CFrame *= shake:Update(dt)
    end)

    -- Clean up
    return function()
        RunService:UnbindFromRenderStep("CameraShake")
    end
end

function IceCreamExtravaganzaCamera.shake()
    shake:Impulse(1)
end

return IceCreamExtravaganzaCamera
