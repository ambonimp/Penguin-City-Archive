local PetEditorScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Shared.Maid)
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
local wasLastNameFiltered = false
local newName: string | nil
local currentPetData: PetConstants.PetData | nil
local currentPetDataIndex: string | nil
local lastBootData: table | nil
local widget: Widget.Widget

local function unfocus()
    if textBox:IsFocused() then
        textBox:ReleaseFocus()
    end
end

local function yieldWhileFiltering()
    while isFiltering do
        task.wait()
    end
end

local function filterAndUpdateNameFromTextbox()
    -- RETURN: Currently filtering
    if isFiltering then
        return
    end
    isFiltering = true

    unfocus()

    local newDirtyName = textBox.Text

    local filteredName = TextFilterUtil.filter(newDirtyName, Players.LocalPlayer.UserId)
    local wasFiltered = (filteredName == nil) or TextFilterUtil.wasFiltered(newDirtyName, filteredName)

    unfocus()

    textBox.Text = filteredName
    widget:SetText(filteredName)

    local isNewNameDifferentAndGood = not wasFiltered and filteredName ~= currentPetData.Name
    if isNewNameDifferentAndGood then
        newName = filteredName
    end

    wasLastNameFiltered = wasFiltered
    isFiltering = false
end

function PetEditorScreen.Init()
    local function exitState()
        -- If filtering, we revert back to this state if it was filtered!
        if isFiltering then
            task.defer(function()
                yieldWhileFiltering()

                if wasLastNameFiltered and lastBootData then
                    UIController.getStateMachine():Push(UIConstants.States.PetEditor, lastBootData)
                end
            end)
        end

        UIController.getStateMachine():Remove(UIConstants.States.PetEditor)
    end

    -- Buttons
    do
        leftButton:SetText("Save and Equip")
        leftButton:SetColor(Color3.fromRGB(229, 142, 237))
        leftButton:Mount(leftButtonFrame, true)
        leftButton.Pressed:Connect(function()
            -- Update internal name if we were typing when we pressed
            if textBox:IsFocused() then
                filterAndUpdateNameFromTextbox()
            end
            yieldWhileFiltering()

            -- Name / Equip
            if newName and currentPetDataIndex then
                print("request", newName)
                PetController.requestSetPetName(newName, currentPetDataIndex)
            end
            PetController.equipPetRequest(currentPetDataIndex)

            exitState()
        end)

        rightButton:SetText("Save")
        rightButton:SetColor(Color3.fromRGB(50, 195, 185))
        rightButton:Mount(rightButtonFrame, true)
        rightButton.Pressed:Connect(function()
            -- Update internal name if we were typing when we pressed
            if textBox:IsFocused() then
                filterAndUpdateNameFromTextbox()
            end
            yieldWhileFiltering()

            -- Name
            if newName and currentPetDataIndex then
                print("request", newName)
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
    lastBootData = data

    -- Read Data
    local petData: PetConstants.PetData = data.PetData
    local petDataIndex: string = data.PetDataIndex

    currentPetData = petData
    currentPetDataIndex = petDataIndex

    openMaid:Cleanup()

    -- Setup UI
    widget = Widget.diverseWidgetFromPetData(petData)
    widget:Mount(widgetHolder, true)
    openMaid:GiveTask(widget)

    -- Init Textbox
    textBox.Text = petData.Name

    -- Handle name editing
    openMaid:GiveTask(textBox.FocusLost:Connect(filterAndUpdateNameFromTextbox))
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
