local CharacterEditorCamera = {}

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Signal = require(Paths.Shared.Signal)
local UIScaleController = require(Paths.Client.UI.Scaling.UIScaleController)
local CameraController = require(Paths.Client.CameraController)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)

local SUBJECT_SCALE_X = 0.3
local SUBJECT_POSITION_X = 0.3

local camera: Camera = workspace.CurrentCamera
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player.PlayerGui

local subject: Model
local subjectRoot: Part
local subjectCFrame: CFrame, subjectSize: Vector3
local rotationalOffset = { X = -15, Y = 10 }

local screen: ScreenGui = Paths.UI.CharacterEditor
local rotateHitbox: Frame = screen.Rotate

local function lookAtSubject()
    local viewportSize: Vector2 = camera.ViewportSize
    local fov: number = CameraController.getFov()
    local aspectRatio: number = viewportSize.X / viewportSize.Y

    local worldDepth = CameraUtil.getFitDeph(viewportSize, fov, subjectSize * Vector3.new(1 / SUBJECT_SCALE_X, 1, 1))
    local worldWidth: number = aspectRatio * (math.tan(math.rad(fov) / 2) * worldDepth) * 2
    local screenOffset: number = (0.5 - SUBJECT_POSITION_X)

    local cameraOffset: CFrame = CFrame.new(worldWidth * screenOffset, 0, worldDepth)
        * CFrame.fromEulerAnglesYXZ(math.rad(rotationalOffset.X), 0, 0)
    CameraUtil.lookAt(camera, subjectCFrame, cameraOffset)

    -- Orient subject character forward
    subjectRoot.CFrame = subjectCFrame * CFrame.Angles(0, math.rad(fov * aspectRatio * screenOffset + rotationalOffset.Y), 0) -- Align subject character with camera
end

local function onRotationChanged(_, inputState, inputObject)
    if inputState == Enum.UserInputState.Change then
        local deltaY = inputObject.Delta.X * 0.3
        rotationalOffset.Y += deltaY
        subjectRoot.CFrame *= CFrame.fromEulerAnglesXYZ(0, math.rad(deltaY), 0)
    end
end

local function onRotationToggled(_, inputState)
    if inputState == Enum.UserInputState.Begin then
        local mousePosition: Vector2 = UserInputService:GetMouseLocation()
        if table.find(playerGui:GetGuiObjectsAtPosition(mousePosition.X, mousePosition.Y), rotateHitbox) then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
            ContextActionService:BindAction("Rotate", onRotationChanged, false, Enum.UserInputType.MouseMovement, Enum.UserInputType.Touch)
        end
    elseif inputState == Enum.UserInputState.End then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        ContextActionService:UnbindAction("Rotate")
    end
end

function CharacterEditorCamera.look(preview: Model)
    subject = preview
    subjectRoot = subject.HumanoidRootPart
    subjectCFrame, subjectSize = subject:GetBoundingBox()
    subjectCFrame = subject.HumanoidRootPart.CFrame

    local viewportSizeChanged: Signal.Connection
    viewportSizeChanged = UIScaleController.ScaleChanged:Connect(lookAtSubject)
    lookAtSubject()

    ContextActionService:BindAction("ToggleRotation", onRotationToggled, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)

    -- Destroy function
    return function()
        viewportSizeChanged:Disconnect()
        ContextActionService:UnbindAction("TogglePreviewRotation")

        CameraController.setPlayerControl()
    end
end

return CharacterEditorCamera