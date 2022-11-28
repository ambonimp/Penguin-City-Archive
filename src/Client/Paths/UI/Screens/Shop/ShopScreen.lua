local ShopScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Packages.maid)
local TabbedWindow = require(Paths.Client.UI.Elements.TabbedWindow)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local Images = require(Paths.Shared.Images.Images)
local InventoryProductWindow = require(Paths.Client.UI.Screens.Inventory.InventoryProductWindow)
local InventoryPetsWindow = require(Paths.Client.UI.Screens.Inventory.InventoryPetsWindow)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local Products = require(Paths.Shared.Products.Products)
local VehicleController = require(Paths.Client.VehicleController)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local PetController = require(Paths.Client.Pets.PetController)
local CoinsWindow = require(Paths.Client.UI.Screens.Shop.CoinsWindow)

local screenGui: ScreenGui
local openMaid = Maid.new()
local tabbedWindow: typeof(TabbedWindow.new())

function ShopScreen.Init()
    -- Setup Tabbed Window
    do
        -- Create
        screenGui = Instance.new("ScreenGui")
        screenGui.Enabled = false
        screenGui.Name = "ShopScreen"
        screenGui.Parent = Ui

        tabbedWindow = TabbedWindow.new(UIConstants.States.Shop)
        tabbedWindow:Mount(screenGui)

        -- Close
        tabbedWindow.ClosePressed:Connect(function()
            UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.Shop)
        end)
    end

    -- Tabs
    do
        -- Coins
        tabbedWindow:AddTab("Coins", Images.Coins.Coin)
        tabbedWindow:SetWindowConstructor("Coins", function(parent, maid)
            local coinsWindow = CoinsWindow.new()

            maid:GiveTask(coinsWindow)
            coinsWindow:Mount(parent)
        end)
    end

    -- Register UIState

    UIController.registerStateScreenCallbacks(UIConstants.States.Shop, {
        Boot = ShopScreen.boot,
        Shutdown = nil,
        Maximize = ShopScreen.maximize,
        Minimize = ShopScreen.minimize,
    })
end

function ShopScreen.boot(data: table?)
    openMaid:Cleanup()

    local tabName = data and data.StartTabName or "Coins"
    tabbedWindow:OpenTab(tabName)
end

function ShopScreen.minimize()
    ScreenUtil.outUp(tabbedWindow:GetContainer())
end

function ShopScreen.maximize()
    ScreenUtil.inDown(tabbedWindow:GetContainer())
    screenGui.Enabled = true
end

return ShopScreen
