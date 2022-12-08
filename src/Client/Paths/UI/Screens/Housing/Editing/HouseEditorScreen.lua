local HousingScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local ZoneController = require(Paths.Client.Zones.ZoneController)
local UIController = require(Paths.Client.UI.UIController)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local WideButton = require(Paths.Client.UI.Elements.WideButton)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local FurniturePage = require(Paths.Client.UI.Screens.Housing.Editing.FurniturePage)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
local localPlayer = Players.LocalPlayer
local uiStateMachine = UIController.getStateMachine()

local screenGui: ScreenGui = Paths.UI.Housing

local editToggleContainer: Frame = screenGui.EditToggle
local editToggleButton: typeof(KeyboardButton.new())

local interiorPlot: Model?

-----------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
-- Register UIStates
do
    uiStateMachine:RegisterStateCallbacks(UIConstants.States.HouseEditor, function()
        ScreenUtil.inDown(editToggleContainer)
    end, function()
        ScreenUtil.outUp(editToggleContainer)
    end)
end

-- Manipulate UIStates
do
    local function close()
        uiStateMachine:Remove(UIConstants.States.HouseEditor)
    end

    UIUtil.offsetGuiInset(editToggleContainer)
    editToggleButton = WideButton.red("Stop Edit")
    editToggleButton.Pressed:Connect(function()
        if uiStateMachine:HasState(UIConstants.States.HouseEditor) then
            close()
        else
            uiStateMachine:Push(UIConstants.States.HouseEditor, {
                InteriorPlot = interiorPlot,
            })
        end
    end)
    editToggleButton:Mount(editToggleContainer, true)
    ScreenUtil.outUp(editToggleContainer)

    UIController.registerStateCloseCallback(UIConstants.States.HouseEditor, function()
        if uiStateMachine:HasState(UIConstants.States.HouseEditor) then
            close()
        end
    end)

    ZoneController.ZoneChanged:Connect(function(old, new)
        if tostring(old.ZoneId) == tostring(localPlayer.UserId) and tostring(new.ZoneId) ~= tostring(localPlayer.UserId) then --TODO: not sure where else to do this
            if uiStateMachine:HasState(UIConstants.States.HouseEditor) then
                close()
            elseif uiStateMachine:HasState(UIConstants.States.FurniturePlacement) then
                uiStateMachine:Remove(UIConstants.States.FurniturePlacement)
            end
        end
    end)
end

-- Setup UI
do
    -- Show
    screenGui.Enabled = true
end

return HousingScreen
