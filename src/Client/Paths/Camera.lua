local Camera = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TweenableValue = require(Paths.Shared.TweenableValue)
local Maid = require(Paths.Packages.maid)
local MathUtil = require(Paths.Shared.Utils.MathUtil)

-- We transform our followMopuse cframes into this object space for easy calculation
local ZERO_VECTOR = Vector3.new(0, 0, 0)
local FOLLOW_MOUSE_OBJECT_SPACE = CFrame.new(ZERO_VECTOR, Vector3.new(1, 0, 0))

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
    - xDegrees: The maximum rotation on the X axis (+-)
    - yDegrees: The maximum rotation on the Y axis (+-)
    - Returns a Maid this process is attached to
]]
function Camera.followMouse(xDegrees: number, yDegrees: number)
    -- ERROR: Not scriptable!
    if not camera.CameraType == Enum.CameraType.Scriptable then
        error("Camera is not set to scriptable! Use Camera.setScriptable()")
    end

    -- WARN: Not built to support degrees > 90
    if xDegrees > 90 or yDegrees > 90 then
        warn(("followMouse not built to handle degrees greater than 90 (x: %d, y: %d)"):format(xDegrees, yDegrees))
    end

    -- Setup Maids
    followMouseMaid:Cleanup()

    local thisFollowMouseMaid = Maid.new()
    followMouseMaid:GiveTask(thisFollowMouseMaid)

    -- Read beginning camera state
    local cameraCFrame = camera.CFrame

    thisFollowMouseMaid:GiveTask(RunService.RenderStepped:Connect(function()
        --[[
            Calculate where our mouse is in relation to the center of the screen
            Top left would be (-1,-1)
            Bottom right would be (1, 1)
        ]]
        local mouseLocation = UserInputService:GetMouseLocation()
        local viewportSize = camera.ViewportSize
        local xScalar = MathUtil.map(mouseLocation.X, 0, viewportSize.X, -1, 1)
        local yScalar = MathUtil.map(mouseLocation.Y, 0, viewportSize.Y, -1, 1)

        --[[
            From our relative mouse position, calculate a new point on a sphere around our camera position.
            We will calculate a vector from the origin to this new point to change the angle of the camera.
            How much this point moves vs our relative mouse position is dictated by xDegrees and yDegrees.
            E.g., if xDegrees=90, moving our mouse to the far right will rotate our point 90 degrees to the right.
        ]]
        local xRad = math.rad(xScalar * xDegrees)
        local yRad = math.rad(yScalar * yDegrees)
        local spherePoint = Vector3.new(math.cos(xRad), math.sin(yRad), -math.sin(xRad))

        --[[
            We now transform this "sphere point" context into the context of our current camera!
            Update our camera CFrame.
        ]]
        local mouseObjectSpace = CFrame.new(ZERO_VECTOR, spherePoint)
        local relativeDifference = mouseObjectSpace:ToObjectSpace(FOLLOW_MOUSE_OBJECT_SPACE)
        local newCameraCFrame = cameraCFrame:ToWorldSpace(relativeDifference)

        camera.CFrame = newCameraCFrame
    end))

    return thisFollowMouseMaid
end

return Camera
