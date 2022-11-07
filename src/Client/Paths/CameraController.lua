local CameraController = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TweenableValue = require(Paths.Shared.TweenableValue)
local Maid = require(Paths.Packages.maid)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local BasePartUtil = require(Paths.Shared.Utils.BasePartUtil)
local VectorUtil = require(Paths.Shared.Utils.VectorUtil)
local Vector3Util = require(Paths.Shared.Utils.Vector3Util)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)

-- We transform our followMopuse cframes into this object space for easy calculation
local ZERO_VECTOR = Vector3.new(0, 0, 0)
local FOLLOW_MOUSE_OBJECT_SPACE = CFrame.new(ZERO_VECTOR, Vector3.new(1, 0, 0))
local ALIGN_CHARACTER_HEIGHT_GAIN_PER_UNIT = 0.2

local followMouseMaid = Maid.new()
local camera = Workspace.CurrentCamera
local tweenableFov =
    TweenableValue.new("NumberValue", camera.FieldOfView, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))

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

function CameraController.isCameraScriptable()
    return camera.CameraType == Enum.CameraType.Scriptable
end

function CameraController.isPlayerControlled()
    return camera.CameraType == Enum.CameraType.Custom
end

function CameraController.setFov(fov: number, animationLength: number?)
    tweenableFov:Haste(fov, animationLength)
end

function CameraController.getFov()
    return tweenableFov:GetGoal()
end

function CameraController.resetFov(animationLength: number?)
    if animationLength then
        tweenableFov:HasteReset(animationLength)
    else
        tweenableFov:TweenReset()
    end
end

function CameraController.lookAt(subject: BasePart | Model | BasePartUtil.PsuedoBasePart, offset: Vector3, fov: number?): (Tween, CFrame)
    fov = fov or tweenableFov:GetGoal()
    local cframe: CFrame, size: Vector3
    if subject:IsA("Model") then
        cframe, size = subject:GetBoundingBox()
    else
        cframe = subject.CFrame
        size = subject.Size
    end

    return CameraUtil.lookAt(
        camera,
        cframe,
        CFrame.new(0, 0, CameraUtil.getFitDeph(camera.ViewportSize, fov, size)) + offset,
        TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    )
end

function CameraController.alignCharacter()
    -- RETURN: Must be in control
    if not CameraController.isPlayerControlled() then
        return
    end

    -- RETURN: No character
    local character = Players.LocalPlayer.Character
    if not character then
        return
    end

    local currentDistance: number = (camera.CFrame.Position - camera.Focus.Position).Magnitude

    local characterLookVectorXZ = VectorUtil.getUnit(Vector3Util.getXZComponents(character.PrimaryPart.CFrame.LookVector))
    local cameraPosition = -characterLookVectorXZ * currentDistance
        + Vector3.new(0, ALIGN_CHARACTER_HEIGHT_GAIN_PER_UNIT * currentDistance, 0)

    camera.CFrame = CFrame.new(camera.Focus.Position + cameraPosition, camera.Focus.Position)
end

function CameraController.viewCameraModel(cameraModel: Model)
    -- ERROR: No lens!
    local lens: Part = cameraModel.Lens
    if not (lens and lens:IsA("BasePart")) then
        error(("Passed model %s is a bad camera model"):format(cameraModel:GetFullName()))
    end

    -- ERROR: Not scriptable!
    if not CameraController.isCameraScriptable() then
        error("CameraController is not set to scriptable! Use CameraController.setScriptable()")
    end

    camera.CFrame = CFrame.new(lens.Position, lens.Position + lens.CFrame.LookVector)
end

--[[
    - xDegrees: The maximum rotation on the X axis (+-)
    - yDegrees: The maximum rotation on the Y axis (+-)
    - Returns a Maid this process is attached to
]]
function CameraController.followMouse(xDegrees: number, yDegrees: number)
    -- ERROR: Not scriptable!
    if not CameraController.isCameraScriptable() then
        error("CameraController is not set to scriptable! Use CameraController.setScriptable()")
    end

    -- WARN: Not built to support degrees > 90
    if xDegrees > 90 or yDegrees > 90 then
        warn(("followMouse not built to handle degrees greater than 90 (x: %d, y: %d)"):format(xDegrees, yDegrees))
    end

    -- Setup Maids
    followMouseMaid:Cleanup()

    local thisFollowMouseMaid = Maid.new()
    followMouseMaid:GiveTask(function()
        -- May have been cleaned up/destroyed somewhere else beforehand
        if thisFollowMouseMaid.Destroy then
            thisFollowMouseMaid:Destroy()
        end
    end)

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

return CameraController
