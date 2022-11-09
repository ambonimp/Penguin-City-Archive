local InventoryScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Packages.maid)
local TabbedWindow = require(Paths.Client.UI.Elements.TabbedWindow)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local Images = require(Paths.Shared.Images.Images)

local screenGui: ScreenGui
local openMaid = Maid.new()
local tabbedWindow: typeof(TabbedWindow.new())

function InventoryScreen.Init()
    -- Setup Tabbed Window
    do
        -- Create
        screenGui = Instance.new("ScreenGui")
        screenGui.Enabled = false
        screenGui.Name = "InventoryScreen"
        screenGui.Parent = Ui

        tabbedWindow = TabbedWindow.new()
        tabbedWindow:Mount(screenGui)

        -- Close
        local closeButton = ExitButton.new()
        closeButton:Mount(tabbedWindow:GetContainer().Background.CloseButton)
        closeButton.Pressed:Connect(function()
            UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.Inventory)
        end)

        -- Tabs
        tabbedWindow:AddTab("Hoverboards", Images.Icons.Hoverboard)
        tabbedWindow:AddTab("Pets", Images.Icons.Pets)
        tabbedWindow:AddTab("Food", Images.Icons.Food)
        tabbedWindow:AddTab("Toys", Images.Icons.Toy)
        tabbedWindow:AddTab("Roleplay", Images.Icons.Roleplay)
    end

    -- Register UIState
    do
        local function enter()
            InventoryScreen.open()
        end

        local function exit()
            InventoryScreen.close()
        end

        UIController.getStateMachine():RegisterStateCallbacks(UIConstants.States.Inventory, enter, exit)
    end
end

function InventoryScreen.open()
    openMaid:Cleanup()

    ScreenUtil.inDown(tabbedWindow:GetContainer())
    screenGui.Enabled = true
end

function InventoryScreen.close()
    ScreenUtil.outUp(tabbedWindow:GetContainer())
end

return InventoryScreen
