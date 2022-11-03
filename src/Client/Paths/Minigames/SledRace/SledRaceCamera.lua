local SledRaceCamera = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Shake = require(Paths.Shared.Shake)
local Spring = require(Paths.Shared.Spring)

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local spring = Spring.new(Vector3.new(), 8, 2, 5, Vector3.new(3, 1.5, 3))
local shake = Shake.new(12, 2, 0.8, 3.5, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out))

function SledRaceCamera.setup()
    -- Follow character
    local character = player.Character
    local toFollow: BasePart = character.Eyes

    local subject = Instance.new("Part")
    subject.Transparency = 1
    subject.Size = Vector3.new(1, 1, 1)
    subject.Position = toFollow.Position
    subject.Anchored = true
    subject.CanCollide = false
    subject.Parent = Workspace
    camera.CameraSubject = subject
    spring:Reset(subject.Position)

    local following: RBXScriptConnection = RunService.Heartbeat:Connect(function(dt)
        local position: Vector3 = spring:Update(toFollow.Position, dt)
        subject.Position = position
    end)

    -- Shake
    shake:Reset()
    RunService:BindToRenderStep("CameraShake", Enum.RenderPriority.Camera.Value + 1, function(dt)
        camera.CFrame *= shake:Update(dt)
    end)

    -- Clean up
    return function()
        following:Disconnect()
        RunService:UnbindFromRenderStep("CameraShake")
        subject:Destroy()

        if player.Character == character then
            camera.CameraSubject = character.Humanoid
        end
    end
end

function SledRaceCamera.shake(factor)
    shake:Impulse(factor)
end

return SledRaceCamera
