--[[
    Used by the character editor and starting appearance scope
]]
local CharacterPreview = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Shared.Maid)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local CharacterConstants = require(Paths.Shared.Constants.CharacterConstants)
local CoreGui = require(Paths.Client.UI.CoreGui)
local InteractionUtil = require(Paths.Shared.Utils.InteractionUtil)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Signal = require(Paths.Shared.Signal)
local UIScaleController = require(Paths.Client.UI.Scaling.UIScaleController)
local CameraController = require(Paths.Client.CameraController)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)

local IDLE_ANIMATION = InstanceUtil.tree("Animation", { AnimationId = CharacterConstants.Animations.Idle[1].Id })
local ROTATE_SPEED_FACTOR = 0.3

CharacterPreview.Defaults = {
    SubjectScale = 10,
    SubjectPosition = 0,
    RotationalOffset = Vector2.new(-15, 10),
}

local camera = workspace.CurrentCamera

local subject: Model
local subjectRoot: Part
local subjectCFrame: CFrame
local subjectSize: Vector3

local subjectScale = CharacterPreview.Defaults.SubjectScale
local subjectPosition = CharacterPreview.Defaults.SubjectPosition
local rotationalOffset = { X = CharacterPreview.Defaults.RotationalOffset.X, Y = CharacterPreview.Defaults.RotationalOffset.Y }

local function lookAtSubject()
    local viewportSize: Vector2 = camera.ViewportSize
    local fov: number = CameraController.getFov()
    local aspectRatio: number = viewportSize.X / viewportSize.Y

    local worldDepth = CameraUtil.getFitDepth(viewportSize, fov, subjectSize * Vector3.new(subjectScale, 1, 1))
    local worldWidth: number = aspectRatio * (math.tan(math.rad(fov) / 2) * worldDepth) * 2
    local screenOffset: number = -subjectPosition

    local cameraOffset: CFrame = CFrame.new(worldWidth * screenOffset, 0, worldDepth)
        * CFrame.fromEulerAnglesYXZ(math.rad(rotationalOffset.X), 0, 0)
    CameraUtil.lookAt(camera, subjectCFrame, cameraOffset)

    -- Orient subject character forward
    subjectRoot.CFrame = subjectCFrame * CFrame.Angles(0, math.rad(fov * aspectRatio * screenOffset + rotationalOffset.Y), 0) -- Align subject character with camera
end

local function onRotationChanged(_, inputState, inputObject)
    if inputState == Enum.UserInputState.Change then
        local deltaY = inputObject.Delta.X * ROTATE_SPEED_FACTOR
        rotationalOffset.Y += deltaY
        subjectRoot.CFrame *= CFrame.fromEulerAnglesXYZ(0, math.rad(deltaY), 0)
    end
end

local function onRotationToggled(_, inputState)
    if inputState == Enum.UserInputState.Begin then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        ContextActionService:BindAction("Rotate", onRotationChanged, false, Enum.UserInputType.MouseMovement, Enum.UserInputType.Touch)
    elseif inputState == Enum.UserInputState.End then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        ContextActionService:UnbindAction("Rotate")
    end
end

--[[
    Sets up our camera to look at a clone of our character model that we can do what we want with!
    - `SubjectScale`: How much of the screen the model takes up
    - `SubjectPosition`: - to move model to the left, + to move the model to the right
    - `RotationalOffset`: Camera Angle

    Returns { previewCharacter: Model, maid: Maid }. Maid cleans up whole process.
]]
function CharacterPreview.preview(config: {
    SubjectScale: number?,
    SubjectPosition: number?,
    RotationalOffset: Vector2?,
}?)
    -- Read Config
    config = config or {}
    subjectScale = config.SubjectScale or CharacterPreview.Defaults.SubjectScale
    subjectPosition = config.SubjectPosition or CharacterPreview.Defaults.SubjectPosition
    local useRotationalOffset = config.RotationalOffset or CharacterPreview.Defaults.RotationalOffset
    rotationalOffset = { X = useRotationalOffset.X, Y = useRotationalOffset.Y }

    local maid = Maid.new()

    -- Get a previewCharacter
    local character = Players.LocalPlayer.Character
    if not character then
        error("No Player Character!")
    end

    local previewCharacter = character:Clone()
    previewCharacter:WaitForChild("HumanoidRootPart").Anchored = true
    previewCharacter.Name = "PreviewCharacter"
    previewCharacter.Parent = Workspace
    previewCharacter.Humanoid:WaitForChild("Animator"):LoadAnimation(IDLE_ANIMATION):Play()
    maid:GiveTask(previewCharacter)

    -- Disable Core Systems
    CoreGui.disable()
    InteractionUtil.hideInteractions(script.Name)
    CharacterUtil.hideCharacters(script.Name)
    maid:GiveTask(function()
        CoreGui.enable()
        InteractionUtil.showInteractions(script.Name)
        CharacterUtil.showCharacters(script.Name)
    end)

    -- Setup
    subject = previewCharacter
    subjectRoot = subject.HumanoidRootPart
    subjectCFrame, subjectSize = subject:GetBoundingBox()
    subjectCFrame = subject.HumanoidRootPart.CFrame

    local viewportSizeChanged: Signal.Connection
    viewportSizeChanged = UIScaleController.ScaleChanged:Connect(lookAtSubject)
    lookAtSubject()

    ContextActionService:BindAction("ToggleRotation", onRotationToggled, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)

    -- Destroy function
    maid:GiveTask(function()
        viewportSizeChanged:Disconnect()
        ContextActionService:UnbindAction("ToggleRotation")
        CameraController.setPlayerControl()
    end)

    return previewCharacter, maid
end

return CharacterPreview
