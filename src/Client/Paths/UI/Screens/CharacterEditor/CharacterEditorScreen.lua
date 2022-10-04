local CharacterEditorScreen = {}

-- Dependecies
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local CharacterConstants = require(Paths.Shared.Constants.CharacterConstants)
local Maid = require(Paths.Packages.maid)
local Remotes = require(Paths.Shared.Remotes)
local InteractionUtil = require(Paths.Shared.Utils.InteractionUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local UIController = require(Paths.Client.UI.UIController)
local UIScaleController = require(Paths.Client.UI.Scaling.UIScaleController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)
local DataController = require(Paths.Client.DataController)
local CameraController = require(Paths.Client.CameraController)
local CoreGui = require(Paths.Client.UI.CoreGui)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local CharacterEditorConstants = require(Paths.Client.UI.Screens.CharacterEditor.CharacterEditorConstants)
local CharacterEditorCategory = require(Paths.Client.UI.Screens.CharacterEditor.CharacterEditorCategory)

-- Constants
local IDLE_ANIMATION = InstanceUtil.tree("Animation", { AnimationId = CharacterConstants.Animations.Idle[1].Id })

local CAMERA_ROTATIONAL_OFFSET = math.rad(10)
local CHARACTER_SCALE_X = 0.3
local CHARACTER_POSITION_X = 0.3

local DEFAULT_CATEGORY = "Hat"

-- Members
local canOpen: boolean = true

local camera: Camera = workspace.CurrentCamera
local player = Players.LocalPlayer

local screen: ScreenGui = Paths.UI.CharacterEditor
local menu: Frame = screen.Edit
local body: Frame = menu.Body
local categoryTabs: Frame = menu.Tabs
local selectedTab: Frame = categoryTabs.SelectedTab
local uiStateMachine = UIController.getStateMachine()

local categories: { [string]: typeof(CharacterEditorCategory.new("")) } = {}
local currentCategory: string
local pCharacter: Model
local pCharacterCFrame: CFrame, pCharacterSize: Vector3

local session = Maid.new()

local function lookAtPreviewCharacter(viewportSize: Vector2)
    local fov: number = CameraController.getFov()
    camera.FieldOfView = fov
    local aspectRatio: number = viewportSize.X / viewportSize.Y

    local worldDeph: number = CameraUtil.getFitDeph(viewportSize, fov, pCharacterSize * Vector3.new(1 / CHARACTER_SCALE_X, 1, 1))
    local worldWidth: number = aspectRatio * (math.tan(math.rad(fov) / 2) * worldDeph) * 2
    local screenOffset: number = (0.5 - CHARACTER_POSITION_X) -- Character is normally center screen
    CameraUtil.lookAt(camera, pCharacterCFrame, Vector3.new(worldWidth * screenOffset, 0, worldDeph))

    -- Orient preview character forward
    local humanoidRootPart = pCharacter.HumanoidRootPart
    humanoidRootPart.CFrame = pCharacterCFrame * CFrame.Angles(0, math.rad(fov * aspectRatio) * screenOffset + CAMERA_ROTATIONAL_OFFSET, 0) -- Align preview character with camera
end

-- Initialize categories
do
    for categoryName in CharacterEditorConstants do
        categories[categoryName] = CharacterEditorCategory.new(categoryName)

        -- Routing
        local page = body[categoryName]
        local tab = categoryTabs[categoryName]

        local function openTab()
            if currentCategory then
                body[currentCategory].Visible = false
                categoryTabs[currentCategory].Visible = true
            end

            page.Visible = true
            tab.Visible = false
            selectedTab.Visible = true
            selectedTab.Icon.Image = tab.Icon.Image
            selectedTab.LayoutOrder = tab.LayoutOrder

            currentCategory = categoryName
        end

        tab.MouseButton1Down:Connect(openTab)
        if categoryName == DEFAULT_CATEGORY then
            openTab()
        end
    end
end

-- Register UIState
do
    local yielding: boolean
    local function openMenu()
        -- RETURN: Menu is already open
        if not canOpen then
            return
        end

        canOpen = false

        -- RETURN: No character
        local character: Model = player.Character
        if not character then
            uiStateMachine:Pop()
            return
        end

        -- Only open character editor when the player is on the floor
        yielding = true

        local humanoid: Humanoid = character.Humanoid
        local state: Enum.HumanoidStateType = humanoid:GetState()

        repeat
            state = humanoid:GetState()

            if state == Enum.HumanoidStateType.Seated then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                humanoid:ChangeState(Enum.HumanoidStateType.PlatformStanding)
                task.wait(0.1) -- Give it time to stand up
            end

            if state == Enum.HumanoidStateType.Dead then
                uiStateMachine:PopIfStateOnTop(UIConstants.States.CharacterEditor)
                return
            elseif state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Running then
                yielding = false
            end

            task.wait()
        until not yielding

        -- Create a testing dummy where changes to the players appearance can be previewed really quickly, hide the actual character
        character:WaitForChild("HumanoidRootPart").Anchored = true

        pCharacter = character:Clone()
        pCharacter.Name = "CharacterEditorPreview"
        pCharacter.Parent = Workspace
        pCharacter.Humanoid:WaitForChild("Animator"):LoadAnimation(IDLE_ANIMATION):Play()
        session:GiveTask(pCharacter)

        -- Make camera look at preview character
        pCharacterCFrame, pCharacterSize = pCharacter:GetBoundingBox()
        pCharacterCFrame = pCharacter.HumanoidRootPart.CFrame
        lookAtPreviewCharacter(camera.ViewportSize)
        session:GiveTask(UIScaleController.ViewportSizeChanged:Connect(lookAtPreviewCharacter))

        -- Make categories aware of starting appearance
        local appearanceDescription: CharacterEditorCategory.AppearanceChange = DataController.get("Appearance")
        for name, category in categories do
            category:EquipItem(appearanceDescription[name])
            category:SetPreviewCharacter(pCharacter)
        end

        -- Open menu and hide all other characters
        InteractionUtil.hideInteractions(script.Name)
        CharacterUtil.hideCharacters(script.Name)
        ScreenUtil.inLeft(menu)
        CoreGui.disable()
    end

    local function exitMenu()
        yielding = false

        if not yielding then
            --Were changes were made to the character's appearance
            local appearanceChanges: CharacterEditorCategory.AppearanceChange = {}
            for _, category in categories do
                TableUtil.merge(appearanceChanges, category:GetChanges())
                category:SetPreviewCharacter("")
            end
            if TableUtil.length(appearanceChanges) ~= 0 then
                -- If so, relay them to the server so they can be verified and applied
                Remotes.invokeServer("UpdateCharacterAppearance", appearanceChanges)
            end

            local character = player.Character
            if character then
                character.HumanoidRootPart.Anchored = false
            end

            session:Cleanup()

            CharacterUtil.showCharacters(script.Name)
            ScreenUtil.out(menu)
            CameraController.setPlayerControl()
            CoreGui.enable()
            InteractionUtil.showInteractions(script.Name)
        end

        local character = player.Character
        if character then
            character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        end

        yielding = false
        canOpen = true
    end

    uiStateMachine:RegisterStateCallbacks(UIConstants.States.CharacterEditor, openMenu, exitMenu)
end

-- Manipulate UIState
do
    local exitButton = ExitButton.new()
    exitButton:Mount(menu.Tabs.Exit, true)
    exitButton.InternalPress:Connect(function()
        uiStateMachine:Pop()
    end)

    -- TODO: Replace this with something on the HUD
    UserInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
        -- RETURN: Game processed event
        if gameProcessedEvent then
            return
        end

        if inputObject.KeyCode == Enum.KeyCode.R then
            local isOpen = uiStateMachine:GetState() == UIConstants.States.CharacterEditor
            if isOpen then
                uiStateMachine:Pop()
            else
                uiStateMachine:Push(UIConstants.States.CharacterEditor)
            end
        end
    end)
end

return CharacterEditorScreen
