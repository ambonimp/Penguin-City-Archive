local CharacterEditorScreen = {}

-- Dependecies
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local CharacterConstants = require(Paths.Shared.Constants.CharacterConstants)
local Remotes = require(Paths.Shared.Remotes)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local DataController = require(Paths.Client.DataController)
local CameraController = require(Paths.Client.CameraController)
local CharacterEditorConstants = require(Paths.Client.UI.Screens.CharacterEditor.CharacterEditorConstants)
local CharacterEditorCategory = require(Paths.Client.UI.Screens.CharacterEditor.CharacterEditorCategory)

-- Constants
local CAM_OFFSET = 0
local IDLE_ANIMATION = InstanceUtil.tree("Animation", { AnimationId = CharacterConstants.Animations.Idle[1].Id })

local DEFAULT_CATEGORY = "BodyType"

-- Members
local canOpen: boolean = true

local screen: ScreenGui = Paths.UI.CharacterEditor
local menu: Frame = screen.Appearance
local categoryPages: Frame = menu.Items
local categoryTabs: Frame = menu.Tabs
local uiStateMachine = UIController.getStateMachine()

local categories: { [string]: typeof(CharacterEditorCategory.new("")) } = {}
local currentCategory: string
local previewCharacter: Model

local player = Players.LocalPlayer

-- Initialize categories
do
    for categoryName in CharacterEditorConstants do
        categories[categoryName] = CharacterEditorCategory.new(categoryName)

        -- Routing
        local page = categoryPages[categoryName]
        local tab = categoryTabs[categoryName]

        local function openTab()
            if currentCategory == categoryName then
                return
            end

            if currentCategory then
                categoryPages[currentCategory].Visible = false
            end

            currentCategory = categoryName
            page.Visible = true
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
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        humanoidRootPart.Anchored = true

        previewCharacter = character:Clone()
        previewCharacter.Name = "CharacterEditorPreview"
        previewCharacter.Parent = Workspace
        previewCharacter.Humanoid:WaitForChild("Animator"):LoadAnimation(IDLE_ANIMATION):Play()

        local appearanceDescription: CharacterEditorCategory.AppearanceChange = DataController.get("Appearance")
        for name, category in categories do
            category:EquipItem(appearanceDescription[name])
            category:SetPreviewCharacter(previewCharacter)
        end

        -- Open menu and make camera look at character, hide all other characters
        CharacterUtil.hideCharacters(script.Name)
        CameraController.lookAt(character, Vector3.new(0, 0, CAM_OFFSET))
        ScreenUtil.inLeft(menu)
    end

    local function exitMenu()
        yielding = false

        if not yielding then
            previewCharacter:Destroy()

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

            CharacterUtil.showCharacters(script.Name)
            CameraController.setPlayerControl()
            ScreenUtil.out(menu)
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
    menu.Header.Close.MouseButton1Down:Connect(function()
        uiStateMachine:PopIfStateOnTop(UIConstants.States.CharacterEditor)
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
