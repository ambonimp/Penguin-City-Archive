local Camera = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TweenableValue = require(Paths.Shared.TweenableValue)
local Maid = require(Paths.Packages.maid)
local MathUtil = require(Paths.Shared.Utils.MathUtil)

local camera = Workspace.CurrentCamera
local followMouseMaid = Maid.new()
local tweenableFov = TweenableValue.new("IntValue", 70, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

tweenableFov:BindToProperty(camera, "FieldOfView")

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

--[[
    - xDegrees: The maximum rotation on the X axis
    - yDegrees: The maximum rotation on the Y axis
    - Returns a Maid this process is attached to
]]
function Camera.followMouse(xDegrees: number, yDegrees: number)
    -- Setup Maids
    followMouseMaid:Cleanup()

    local thisFollowMouseMaid = Maid.new()
    followMouseMaid:GiveTask(thisFollowMouseMaid)

    thisFollowMouseMaid:GiveTask(RunService.RenderStepped:Connect(function()
        -- Read Mouse
        local mouseLocation = UserInputService:GetMouseLocation()
        local viewportSize = camera.ViewportSize
        local xScalar = MathUtil.map(mouseLocation.X, 0, viewportSize.X, -1, 1)
        local yScalar = MathUtil.map(mouseLocation.Y, 0, viewportSize.Y, -1, 1)

        print(xScalar, yScalar)
    end))

    return thisFollowMouseMaid
end

return Camera
