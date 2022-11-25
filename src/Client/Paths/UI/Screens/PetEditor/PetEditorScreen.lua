local PetEditorScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Packages.maid)
local PetConstants = require(Paths.Shared.Pets.PetConstants)
local Widget = require(Paths.Client.UI.Elements.Widget)
local TextFilterUtil = require(Paths.Shared.Utils.TextFilterUtil)
local PetController = require(Paths.Client.Pets.PetController)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)

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
local closeButton = ExitButton.new(UIConstants.States.PetEditor)

local openMaid = Maid.new()

local isFiltering = false
local newName: string | nil
local currentPetDataIndex: string | nil

function PetEditorScreen.Init()
    local function exitState()
        if isFiltering then
            return
        end

        UIController.getStateMachine():Remove(UIConstants.States.PetEditor)
    end

    -- Buttons
    do
        leftButton:SetText("Save and Equip")
        leftButton:SetColor(Color3.fromRGB(229, 142, 237))
        leftButton:Mount(leftButtonFrame, true)
        leftButton.Pressed:Connect(function()
            if newName and currentPetDataIndex then
                PetController.requestSetPetName(newName, currentPetDataIndex)
            end
            PetController.equipPetRequest(currentPetDataIndex)

            exitState()
        end)

        rightButton:SetText("Save")
        rightButton:SetColor(Color3.fromRGB(50, 195, 185))
        rightButton:Mount(rightButtonFrame, true)
        rightButton.Pressed:Connect(function()
            if newName and currentPetDataIndex then
                PetController.requestSetPetName(newName, currentPetDataIndex)
            end

            exitState()
        end)

        closeButton:Mount(closeButtonFrame, true)
        closeButton.Pressed:Connect(exitState)
    end

    -- Register UIState
    UIController.registerStateScreenCallbacks(UIConstants.States.PetEditor, {
        Boot = PetEditorScreen.boot,
        Shutdown = PetEditorScreen.shutdown,
        Maximize = PetEditorScreen.maximize,
        Minimize = PetEditorScreen.minimize,
    })
end

function PetEditorScreen.boot(data: table)
    local petData: PetConstants.PetData = data.PetData
    local petDataIndex: string = data.PetDataIndex

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
        -- RETURN: Currently filtering
        if isFiltering then
            return
        end

        local newDirtyName = textBox.Text

        isFiltering = true
        local filteredName = TextFilterUtil.filter(newDirtyName, Players.LocalPlayer.UserId)
        local wasFiltered = (filteredName == nil) or TextFilterUtil.wasFiltered(newDirtyName, filteredName)
        isFiltering = false

        textBox.Text = filteredName
        if not wasFiltered then
            currentName = filteredName

            newName = currentName
            widget:SetText(currentName)
        end
    end))

    openMaid:GiveTask(textBox.Focused:Connect(function()
        -- Don't allow new entry if currently filtering
        if isFiltering then
            textBox:ReleaseFocus()
        end
    end))
end

function PetEditorScreen.shutdown()
    newName = nil
    isFiltering = false
    currentPetDataIndex = nil
end

function PetEditorScreen.maximize()
    ScreenUtil.inDown(screenGui.Back)
    screenGui.Enabled = true
end

function PetEditorScreen.minimize()
    ScreenUtil.outUp(screenGui.Back)
end

return PetEditorScreen
