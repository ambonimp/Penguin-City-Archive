local PetEditorScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Packages.maid)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local PetConstants = require(Paths.Shared.Pets.PetConstants)
local Widget = require(Paths.Client.UI.Elements.Widget)
local TextFilterUtil = require(Paths.Shared.Utils.TextFilterUtil)
local PetsController = require(Paths.Client.Pets.PetsController)

local screenGui: ScreenGui = Ui.PetEditor
local contents: Frame = screenGui.Back.Contents
local leftButtonFrame: Frame = contents.Buttons.Left
local rightButtonFrame: Frame = contents.Buttons.Right
local middleFrame: Frame = contents.Middle
local closeButtonFrame: Frame = screenGui.Back.CloseButton
local widgetHolder: Frame = middleFrame.WidgetHolder
local textBox: TextBox = middleFrame.Edit.TextBox

local leftButton = KeyboardButton.new()
local rightButton = KeyboardButton.new()
local closeButton = ExitButton.new()

local openMaid = Maid.new()

local isFiltering = false
local newName: string | nil
local currentPetDataIndex: string | nil

function PetEditorScreen.Init()
    local function exitState()
        if isFiltering then
            return
        end

        UIController.getStateMachine():Remove(UIConstants.States.GenericPrompt)
    end

    -- Buttons
    do
        leftButton:SetText("Save and Equip")
        leftButton:SetColor(Color3.fromRGB(229, 142, 237))
        leftButton:Mount(leftButtonFrame, true)
        leftButton.Pressed:Connect(function()
            exitState()

            if newName and currentPetDataIndex then
                PetsController.setPetName(newName, currentPetDataIndex)
            end
            warn("todo equip")
        end)

        rightButton:SetText("Save")
        rightButton:SetColor(Color3.fromRGB(50, 195, 185))
        rightButton:Mount(rightButtonFrame, true)
        rightButton.Pressed:Connect(function()
            exitState()

            if newName and currentPetDataIndex then
                PetsController.setPetName(newName, currentPetDataIndex)
            end
        end)

        closeButton:Mount(closeButtonFrame, true)
        closeButton.Pressed:Connect(exitState)
    end

    -- Register UIState
    do
        local function enter(data: table)
            PetEditorScreen.open(data.PetData, data.PetDataIndex)
        end

        local function exit()
            PetEditorScreen.close()
        end

        UIController.getStateMachine():RegisterStateCallbacks(UIConstants.States.PetEditor, enter, exit)
    end
end

function PetEditorScreen.open(petData: PetConstants.PetData, petDataIndex: string)
    currentPetDataIndex = petDataIndex

    openMaid:Cleanup()

    -- Setup UI
    local widget = Widget.diverseWidgetFromPetData(petData)
    widget:Mount(widgetHolder, true)
    openMaid:GiveTask(widget)

    local currentName = petData.Name
    textBox.Text = currentName

    -- Handle name editing
    openMaid:GiveTask(textBox.FocusLost:Connect(function()
        local newDirtyName = textBox.Text

        isFiltering = true
        local filterResult = TextFilterUtil.filter(newDirtyName, Players.LocalPlayer.UserId)
        local filteredName = filterResult and filterResult:GetNonChatStringForBroadcastAsync()
        local wasFiltered = (filteredName == nil) or TextFilterUtil.wasFiltered(newDirtyName, filteredName)
        isFiltering = false

        if wasFiltered then
            textBox.Text = currentName
        else
            currentName = filteredName

            newName = currentName
            textBox.Text = currentName
            widget:SetText(currentName)
        end
    end))

    screenGui.Enabled = true
end

function PetEditorScreen.close()
    newName = nil
    isFiltering = false
    currentPetDataIndex = nil

    screenGui.Enabled = false
end

return PetEditorScreen
