local HousingUI = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local Limiter = require(Paths.Shared.Limiter)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local HousingController: typeof(require(Paths.Client.HousingController))
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local EditMode: typeof(require(Paths.Client.HousingController.EditMode))

local DEBOUNCE_TIME = 0.2
local DEBOUNCE_SCOPE = "HousingScreen"
local DEBOUNCE_MOUNT = {
    Key = "HousingEdit",
    Timeframe = 0.5,
}

local templates = Paths.Templates.Housing
local screenGui: ScreenGui = Paths.UI.Housing
local edit: Frame = screenGui.Edit
local paint: Frame = screenGui.Paint
HousingUI.itemMove = screenGui.ItemMove
local enterEdit: TextButton = screenGui.EnterEdit
local exitButton = KeyboardButton.new()
--local editCloseButton: ImageButton = edit.Close.Button
local uiStateMachine = UIController.getStateMachine()

local function EditButtonStateChanged()
    local isOpen = uiStateMachine:GetState() == UIConstants.States.HousingEdit
    if isOpen then
        uiStateMachine:Pop()
    else
        uiStateMachine:Push(UIConstants.States.HousingEdit)
    end
end

function HousingUI.Init()
    HousingController = require(Paths.Client.HousingController)

    exitButton:SetColor(UIConstants.Colors.Buttons.CloseRed, true)
    exitButton:Mount(edit.ExitButton, true)
    exitButton:SetPressedDebounce(DEBOUNCE_TIME)
    exitButton:SetIcon("rbxassetid://10979113086")
    exitButton:SetCornerRadius(1)
end

function HousingUI.Start()
    EditMode = require(Paths.Client.HousingController.EditMode)
end

function HousingUI.openBottomEdit()
    ScreenUtil.inUp(edit)
end

function HousingUI.closeBottomEdit()
    ScreenUtil.outDown(edit)
end

function HousingUI.openColorEdit()
    ScreenUtil.inLeft(paint)
end

function HousingUI.closeColorEdit()
    ScreenUtil.outLeft(paint)
end

function HousingUI.EnterEdit()
    HousingController.isEditing = true
    enterEdit.Text = "Exit Edit"
    HousingUI.openBottomEdit()
end

function HousingUI.ExitEdit()
    HousingController.isEditing = false
    enterEdit.Text = "Edit"
    HousingUI.closeBottomEdit()
    EditMode.Reset()
end

function HousingUI.OpenEditButton()
    enterEdit.Visible = true
end

function HousingUI.ExitEditButton()
    enterEdit.Visible = false
end

function HousingUI.HouseEntered(editPerms: boolean)
    if editPerms then
        EditButtonStateChanged()
    end
end

function HousingUI.HouseExited()
    HousingUI.ExitEdit()
    uiStateMachine:Pop()
end

function HousingUI.ItemSelected(item: Model)
    local Height = item:GetExtentsSize().Y
    HousingUI.itemMove.StudsOffset = Vector3.new(0, (Height / 2 * -1), 0)
    HousingUI.itemMove.Adornee = item.PrimaryPart
    HousingUI.itemMove.Enabled = true
end

function HousingUI.ItemDeselected(item: Model)
    HousingUI.itemMove.Adornee = nil
    HousingUI.itemMove.Enabled = false
end

-- Register UIState
do
    local function enter()
        HousingUI.OpenEditButton()
    end

    local function exit()
        HousingUI.ExitEditButton()
    end

    uiStateMachine:RegisterStateCallbacks(UIConstants.States.HousingEdit, enter, exit)
end

-- Manipulate UIState
do
    enterEdit.MouseButton1Down:Connect(function()
        if HousingController.isEditing then
            HousingUI.ExitEdit()
        else
            HousingUI.EnterEdit()
        end
    end)
    --[[
    editCloseButton.MouseButton1Down:Connect(function()
        HousingUI.ExitEdit() -- uiStateMachine:PopIfStateOnTop(UIConstants.States.HousingEdit)
    end)]]
end

-- Setup UI
do
    -- Show
    screenGui.Enabled = true
    edit.Visible = false
end

return HousingUI
