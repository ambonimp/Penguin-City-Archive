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
local closeButton: ImageButton = edit.Close.Button
local uiStateMachine = UIController.getStateMachine()

function HousingUI.Init()
    HousingController = require(Paths.Client.HousingController)
end

function HousingUI.openEdit()
    enterEdit.Text = "Exit Edit"
    ScreenUtil.inUp(edit)
end

function HousingUI.exitEdit()
    enterEdit.Text = "Edit"
    ScreenUtil.outDown(edit)
end

-- Register UIState
do
    local function enter()
        HousingUI.openEdit()
    end

    local function exit()
        HousingUI.exitEdit()
    end

    uiStateMachine:RegisterStateCallbacks(UIConstants.States.HousingEdit, enter, exit)
end

-- Manipulate UIState
do
    closeButton.MouseButton1Down:Connect(function()
        uiStateMachine:PopIfStateOnTop(UIConstants.States.HousingEdit)
    end)

    -- TODO: Replace this with something on the HUD

    enterEdit.MouseButton1Down:Connect(function()
        local isOpen = uiStateMachine:GetState() == UIConstants.States.HousingEdit
        if isOpen then
            uiStateMachine:Pop()
        else
            uiStateMachine:Push(UIConstants.States.HousingEdit)
        end
    end)
end

-- Setup UI
do
    -- Show
    screenGui.Enabled = true
    edit.Visible = false
end

return HousingUI
