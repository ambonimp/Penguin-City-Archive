local Camera = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TweenableValue = require(Paths.Shared.TweenableValue)

local camera = Workspace.CurrentCamera

local tweenableFov = TweenableValue.new("IntValue", 70, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
tweenableFov:BindToProperty(camera, "FieldOfView")

function Camera.getCamera()
    return camera
end

function Camera.setScriptable()
    camera.CameraType = Enum.CameraType.Scriptable
end

function Camera.setPlayerControl()
    camera.CameraType = Enum.CameraType.Custom
end

function Camera.viewCameraModel(cameraModel: Model)
    -- ERROR: No lens!
    local lens: Part = cameraModel.Lens
    if not (lens and lens:IsA("BasePart")) then
        error(("Passed model %s is a bad camera model"):format(cameraModel:GetFullName()))
    end

    -- ERROR: Not scriptable!
    if not camera.CameraType == Enum.CameraType.Scriptable then
        error("Camera is not set to scriptable! Use Camera.setScriptable()")
    end

    camera.CFrame = CFrame.new(lens.Position, lens.Position + lens.CFrame.LookVector)
end

function Camera.setFov(fov: number, animationLength: number?)
    tweenableFov:Set(fov, animationLength)
end

function Camera.resetFov(animationLength: number?)
    tweenableFov:Reset(animationLength)
end

function Camera.getCamera()
    return camera
end

function Camera.setScriptable()
    camera.CameraType = Enum.CameraType.Scriptable
end

function Camera.setPlayerControl()
    camera.CameraType = Enum.CameraType.Custom
end

function Camera.viewCameraModel(cameraModel: Model)
    -- ERROR: No lens!
    local lens: Part = cameraModel.Lens
    if not (lens and lens:IsA("BasePart")) then
        error(("Passed model %s is a bad camera model"):format(cameraModel:GetFullName()))
    end

    -- ERROR: Not scriptable!
    if not camera.CameraType == Enum.CameraType.Scriptable then
        error("Camera is not set to scriptable! Use Camera.setScriptable()")
    end

    camera.CFrame = CFrame.new(lens.Position, lens.Position + lens.CFrame.LookVector)
end

return Camera
