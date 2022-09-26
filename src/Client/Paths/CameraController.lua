local CameraController = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TweenableValue = require(Paths.Shared.TweenableValue)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)

local camera = Workspace.CurrentCamera

local tweenableFov = TweenableValue.new("NumberValue", 70, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
tweenableFov:BindToProperty(camera, "FieldOfView")

function CameraController.getCamera()
    return camera
end

function CameraController.setScriptable()
    camera.CameraType = Enum.CameraType.Scriptable
end

function CameraController.setPlayerControl()
    camera.CameraType = Enum.CameraType.Custom
end

function CameraController.lookAt(subject: BasePart | Model, offset: Vector3, fov: number?): (Tween, CFrame)
    fov = fov or tweenableFov:GetGoal()
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

function CameraController.viewCameraModel(cameraModel: Model)
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

function CameraController.setFov(fov: number, animationLength: number?)
    tweenableFov:Set(fov, animationLength)
end

function CameraController.resetFov(animationLength: number?)
    tweenableFov:Reset(animationLength)
end

return CameraController
