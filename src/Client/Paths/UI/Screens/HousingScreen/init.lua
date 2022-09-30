local HousingUI = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local Limiter = require(Paths.Shared.Limiter)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local HousingController: typeof(require(Paths.Client.HousingController))

local DEBOUNCE_SCOPE = "HousingScreen"
local DEBOUNCE_MOUNT = {
    Key = "HousingEdit",
    Timeframe = 0.5,
}

local templates = Paths.Templates.Housing
local screenGui: ScreenGui = Paths.UI.Housing
local edit: Frame = screenGui.Edit
local enterEdit: TextButton = screenGui.EnterEdit
local editCloseButton: ImageButton = edit.Close.Button
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
end

function HousingUI.OpenEdit()
    HousingController.isEditing = true
    enterEdit.Text = "Exit Edit"
    ScreenUtil.inUp(edit)
end

function HousingUI.ExitEdit()
    HousingController.isEditing = false
    enterEdit.Text = "Edit"
    ScreenUtil.outDown(edit)
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
            HousingUI.OpenEdit()
        end
    end)

    editCloseButton.MouseButton1Down:Connect(function()
        HousingUI.ExitEdit() -- uiStateMachine:PopIfStateOnTop(UIConstants.States.HousingEdit)
    end)
end

-- Setup UI
do
    -- Show
    screenGui.Enabled = true
    edit.Visible = false
end

return HousingUI
