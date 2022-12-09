local HouseSettingsScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local WideButton = require(Paths.Client.UI.Elements.WideButton)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)

local screenGui: ScreenGui = Paths.UI.HouseSettings
local frame: Frame = screenGui.Settings

local uiStateMachine = UIController.getStateMachine()

local plotAt: Model

-- Register UIState
do
    local function maximize()
        ScreenUtil.sizeIn(frame)
    end

    local function open(data)
        plotAt = data.PlotAt
        screenGui.Enabled = true
        maximize()
    end

    local function close()
        ScreenUtil.sizeOut(frame)
    end

    UIController.registerStateScreenCallbacks(UIConstants.States.PlotSettings, {
        Boot = open,
        Shutdown = close,
        Maximize = maximize,
        Minimize = close,
    })
end

-- Manipulate UIState
do
    local exitButton = ExitButton.new()
    exitButton.Pressed:Connect(function()
        uiStateMachine:Pop()
    end)
    exitButton:Mount(frame.ExitButton, true)
end

do
    local plotChangeButton = WideButton.blue("Change Plot")
    plotChangeButton.Pressed:Connect(function()
        uiStateMachine:Push(UIConstants.States.PlotChanger, { PlotAt = plotAt })
    end)
    plotChangeButton:Mount(frame.Center.PlotChange, true)

    local houseChangeButton = WideButton.blue("Change House")
    houseChangeButton.Pressed:Connect(function()
        uiStateMachine:Push(UIConstants.States.HouseSelectionUI, { PlotAt = plotAt })
    end)
    houseChangeButton:Mount(frame.Center.HouseChange, true)
end

return HouseSettingsScreen
