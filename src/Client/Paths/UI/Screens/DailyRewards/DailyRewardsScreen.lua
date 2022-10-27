local DailyRewardsScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)

local screenGui: ScreenGui = Ui.DailyRewards
local closeButton = ExitButton.new()

function DailyRewardsScreen.Init()
    -- Setup Buttons
    do
        closeButton:Mount(screenGui.Container.CloseButton, true)
        closeButton.Pressed:Connect(function()
            UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.DailyRewards)
        end)
    end

    -- Register UIState
    do
        local function enter()
            DailyRewardsScreen.open()
        end

        local function exit()
            DailyRewardsScreen.close()
        end

        UIController.getStateMachine():RegisterStateCallbacks(UIConstants.States.DailyRewards, enter, exit)
    end

    -- Init Screen
    ScreenUtil.outUp(screenGui.Container)
    task.delay(1, function()
        screenGui.Enabled = true
    end)
end

function DailyRewardsScreen.open()
    ScreenUtil.inDown(screenGui.Container)
end

function DailyRewardsScreen.close()
    ScreenUtil.outUp(screenGui.Container)
end

return DailyRewardsScreen
