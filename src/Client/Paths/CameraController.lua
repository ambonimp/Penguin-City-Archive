local Camera = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TweenableValue = require(Paths.Shared.TweenableValue)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

Camera.FOV = TweenableValue.new("NumberValue", 70, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
Camera.FOV:BindToProperty(camera, "FieldOfView")

--[[
    Lock the player camera and it over so the subject is in view
]]
function Camera.lookAt(subject: BasePart | Model, offset: Vector3, fov: number?): (Tween, CFrame)
    fov = fov or Camera.FOV:GetGoal()
    local _, size
    if typeof(subject == "Model") then
        _, size = subject:GetBoundingBox()
    else
        size = subject.Size
    end

    return CameraUtil.lookAt(
        camera,
        subject,
        Vector3.new(0, 0, CameraUtil.getFitDeph(camera.ViewportSize, fov, size)) + offset,
        TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    )
end

--[[
    Unlock the player camera and have it follow the character
]]
function Camera.reset()
    local character = player.Character
    if character then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = character.Humanoid
    end
end

return Camera
