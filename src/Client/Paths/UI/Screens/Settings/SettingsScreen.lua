local SettingsScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Shared.Maid)
local TabbedWindow = require(Paths.Client.UI.Elements.TabbedWindow)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local Images = require(Paths.Shared.Images.Images)
local VolumeWindow = require(Paths.Client.UI.Screens.Settings.VolumeWindow)

local screenGui: ScreenGui
local openMaid = Maid.new()
local tabbedWindow: typeof(TabbedWindow.new())

function SettingsScreen.Init()
    -- Setup Tabbed Window
    do
        -- Create
        screenGui = Instance.new("ScreenGui")
        screenGui.Enabled = false
        screenGui.Name = "SettingsScreen"
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
        screenGui.Parent = Ui

        tabbedWindow = TabbedWindow.new(UIConstants.States.Settings)
        tabbedWindow:Mount(screenGui)

        -- Close
        tabbedWindow.ClosePressed:Connect(function()
            UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.Settings)
        end)
    end

    -- Tabs
    do
        -- Coins
        tabbedWindow:AddTab("Volume", Images.Settings.VolumeOn)
        tabbedWindow:SetWindowConstructor("Volume", function(parent, maid)
            local volumeWindow = VolumeWindow.new()

            maid:GiveTask(volumeWindow)
            volumeWindow:Mount(parent)
        end)
    end

    -- Register UIState

    UIController.registerStateScreenCallbacks(UIConstants.States.Settings, {
        Boot = SettingsScreen.boot,
        Shutdown = nil,
        Maximize = SettingsScreen.maximize,
        Minimize = SettingsScreen.minimize,
    })
end

function SettingsScreen.boot(data: table?)
    openMaid:Cleanup()

    local tabName = data and data.StartTabName or "Volume"
    tabbedWindow:OpenTab(tabName)
end

function SettingsScreen.minimize()
    ScreenUtil.outUp(tabbedWindow:GetContainer())
end

function SettingsScreen.maximize()
    ScreenUtil.inDown(tabbedWindow:GetContainer())
    screenGui.Enabled = true
end

return SettingsScreen
