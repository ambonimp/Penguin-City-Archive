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
local CharacterEditorConstants = require(script.CharacterEditorConstants)
local CharacterEditorCategory = typeof(script.CharacterEditorCategory)

-- Constants
local CAM_OFFSET = 0
local IDLE_ANIMATION = InstanceUtil.tree("Animation", { AnimationId = CharacterConstants.Animations.Idle[1].Id })

-- Members
local screen: ScreenGui = Paths.UI.CharacterEditor
local menu: Frame = screen.Appearance
local categoryPages: Frame = menu.Items
local uiStateMachine = UIController.getStateMachine()

local categories = {}
local currentCategory: string
local previewCharacter: Model
local appearanceChanges: table

local player = Players.LocalPlayer

-- Methods
function CharacterEditorScreen.Init()
    CharacterEditorCategory = require(script.CharacterEditorCategory)
    for categoryName in CharacterEditorConstants do
        categories[categoryName] = CharacterEditorCategory.new(categoryName)
    end
end

-- Invoke when something needs to previewed on the character
function CharacterEditorScreen.previewAppearanceChange(categoryName: string, itemName: string)
    appearanceChanges[categoryName] = itemName
    CharacterUtil.applyAppearance(previewCharacter, { [categoryName] = itemName })
end

function CharacterEditorScreen.openCategory(category: string)
    if currentCategory == category then
        return
    end

    if currentCategory then
        categoryPages[currentCategory].Visible = false
    end

    currentCategory = category
    categoryPages[currentCategory].Visible = true
end

function CharacterEditorScreen.openMenu(category: string?)
    local character = player.Character
    if not character then
        return
    end

    appearanceChanges = {}

    local appearanceDescription = DataController.get("Appearance")
    for categoryName in CharacterEditorConstants do
        categories[categoryName]:EquipItem(appearanceDescription[categoryName])
    end

    -- Create a testing dummy where changes to the players appearance can be previewed really quickly, hide the actual character
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoidRootPart.Anchored = true

    previewCharacter = character:Clone()
    previewCharacter.Name = "CharacterEditorPreview"
    previewCharacter.Parent = Workspace
    previewCharacter.Humanoid:WaitForChild("Animator"):LoadAnimation(IDLE_ANIMATION):Play()

    -- Open menu and make camera look at character, hide all other characters
    if category then
        CharacterEditorScreen.openCategory(category)
    end

    CharacterUtil.hideCharacters(script.Name)
    CameraController.lookAt(character, Vector3.new(0, 0, CAM_OFFSET))
    ScreenUtil.inLeft(menu)
end

function CharacterEditorScreen.exitMenu()
    --Changes were made to the character's appearance
    if TableUtil.length(appearanceChanges) ~= 0 then
        -- Relay them to the server so they can be verified and applied
        Remotes.invokeServer("UpdateCharacterAppearance", appearanceChanges)
    end

    previewCharacter:Destroy()

    local character = player.Character
    if character then
        character.HumanoidRootPart.Anchored = false
    end

    CharacterUtil.showCharacters(script.Name)
    CameraController.setPlayerControl()
    ScreenUtil.out(menu)
end

-- Register UIState
do
    local function enter()
        CharacterEditorScreen.openMenu()
    end

    local function exit()
        CharacterEditorScreen.exitMenu()
    end

    uiStateMachine:RegisterStateCallbacks(UIConstants.States.CharacterEditor, enter, exit)
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
