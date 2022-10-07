local CharacterEditorScreen = {}

-- Dependecies
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local CharacterConstants = require(Paths.Shared.Constants.CharacterConstants)
local CharacterItems = require(Paths.Shared.Constants.CharacterItems)
local Maid = require(Paths.Packages.maid)
local Remotes = require(Paths.Shared.Remotes)
local InteractionUtil = require(Paths.Shared.Utils.InteractionUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local DataController = require(Paths.Client.DataController)
local CoreGui = require(Paths.Client.UI.CoreGui)
local Button = require(Paths.Client.UI.Elements.Button)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local CharacterEditorCategory = require(Paths.Client.UI.Screens.CharacterEditor.CharacterEditorCategory)
local CharacterEditorCamera = require(Paths.Client.UI.Screens.CharacterEditor.CharacterEditorCamera)

-- Constants
local IDLE_ANIMATION = InstanceUtil.tree("Animation", { AnimationId = CharacterConstants.Animations.Idle[1].Id })
local DEFAULT_CATEGORY = "Shirt"

-- Members
local canOpen: boolean = true

local player: Player = Players.LocalPlayer

local screen: ScreenGui = Paths.UI.CharacterEditor
local menu: Frame = screen.Edit
local tabs: Frame = menu.Tabs
local equippedSlots: Frame = screen.Equipped
local uiStateMachine = UIController.getStateMachine()

local categories: { [string]: typeof(CharacterEditorCategory.new("")) } = {}
local currentCategory: string

local preview: Model
local session = Maid.new()

-- Initialize categories
do
    for categoryName in CharacterItems do
        local category = CharacterEditorCategory.new(categoryName)
        categories[categoryName] = category

        local tabButton = Button.new(category:GetTab())
        tabButton:Mount(tabs)
        tabButton.InternalPress:Connect(function()
            if currentCategory then
                categories[currentCategory]:Close()
            end

            currentCategory = categoryName
            category:Open()
        end)

        if categoryName == DEFAULT_CATEGORY then
            currentCategory = categoryName
            category:Open()
        end
    end

    categories.Outfit.Changed:Connect(function(appearance: CharacterItems.Appearance)
        for categoryName, category in categories do
            local equippedItems: CharacterEditorCategory.EquippedItems = appearance[categoryName]
            if equippedItems then
                category:Equip(equippedItems)
            end
        end
    end)
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

        preview = character:Clone()
        preview.Name = "CharacterEditorPreview"
        preview.Parent = Workspace
        preview.Humanoid:WaitForChild("Animator"):LoadAnimation(IDLE_ANIMATION):Play()
        session:GiveTask(preview)

        for _, category in categories do
            category:SetPreview(preview)
        end

        -- Make camera look at preview character
        session:GiveTask(CharacterEditorCamera.look(preview))

        -- Open menu and hide all other characters
        ScreenUtil.inLeft(menu)
        ScreenUtil.inRight(equippedSlots)

        CoreGui.disable()
        InteractionUtil.hideInteractions(script.Name)
        CharacterUtil.hideCharacters(script.Name)
    end

    local function exitMenu()
        yielding = false

        if not yielding then
            --Were changes were made to the character's appearance?
            local appearanceChanges = {}
            local currentApperance: CharacterItems.Appearance = DataController.get("CharacterAppearance")
            for categoryName, category in categories do
                local equipped = category:GetEquipped()
                if not TableUtil.shallowEquals(currentApperance[categoryName], equipped) then
                    appearanceChanges[categoryName] = equipped
                end
                -- Prevent memory leaks
                category:SetPreview()
            end

            if TableUtil.length(appearanceChanges) ~= 0 then
                -- If so, relay them to the server so they can be verified and applied
                Remotes.invokeServer("UpdateCharacterAppearance", appearanceChanges)
            end

            local character = player.Character
            if character then
                character.HumanoidRootPart.Anchored = false
            end

            ScreenUtil.out(menu)
            ScreenUtil.out(equippedSlots)

            CharacterUtil.showCharacters(script.Name)
            CoreGui.enable()
            InteractionUtil.showInteractions(script.Name)

            session:Cleanup()
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
    exitButton:Mount(screen.Exit, true)
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
