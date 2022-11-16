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
local InventoryProductWindow = require(Paths.Client.UI.Screens.Inventory.InventoryProductWindow)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local Products = require(Paths.Shared.Products.Products)
local VehicleController = require(Paths.Client.VehicleController)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local PetsController = require(Paths.Client.Pets.PetsController)

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
        tabbedWindow.ClosePressed:Connect(function()
            UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.Inventory)
        end)
    end

    -- Tabs
    do
        -- Vehicles
        tabbedWindow:AddTab("Vehicles", Images.Icons.Hoverboard)
        tabbedWindow:SetWindowConstructor("Vehicles", function(parent, maid)
            local inventoryWindow = InventoryProductWindow.new(Images.Icons.Hoverboard, "Vehicles", {
                ProductType = ProductConstants.ProductType.Vehicle,
                AddCallback = function()
                    warn("TODO Teleport to hoverboard shop")
                end,
                Equipping = {
                    Equip = function(product: Products.Product)
                        local vehicleName = ProductUtil.getVehicleProductData(product).VehicleName
                        VehicleController.mountRequest(vehicleName)
                    end,
                    Unequip = function(_product: Products.Product)
                        VehicleController.dismountRequest()
                    end,
                    StartEquipped = VehicleController.getCurrentVehicleName()
                        and ProductUtil.getVehicleProduct(VehicleController.getCurrentVehicleName()),
                },
            })

            maid:GiveTask(inventoryWindow)
            inventoryWindow:GetWindowFrame().Parent = parent
        end)

        -- Clothing (--!! TEMP)
        tabbedWindow:AddTab("Clothes", Images.Icons.Shirt)
        tabbedWindow:SetWindowConstructor("Clothes", function(parent, maid)
            local inventoryWindow = InventoryProductWindow.new(Images.Icons.Shirt, "Clothes", {
                ProductType = ProductConstants.ProductType.CharacterItem,
            })

            maid:GiveTask(inventoryWindow)
            inventoryWindow:GetWindowFrame().Parent = parent
        end)

        -- Housing (--!! TEMP)
        tabbedWindow:AddTab("Housing", Images.Icons.Igloo)
        tabbedWindow:SetWindowConstructor("Housing", function(parent, maid)
            local inventoryWindow = InventoryProductWindow.new(Images.Icons.Igloo, "Housing", {
                ProductType = ProductConstants.ProductType.HouseObject,
                ShowTotals = true,
            })

            maid:GiveTask(inventoryWindow)
            inventoryWindow:GetWindowFrame().Parent = parent
        end)

        -- StampBook (--!! TEMP)
        tabbedWindow:AddTab("StampBook", Images.Icons.Stamp)
        tabbedWindow:SetWindowConstructor("StampBook", function(parent, maid)
            local inventoryWindow = InventoryProductWindow.new(Images.Icons.Stamp, "Stamp Book", {
                ProductType = ProductConstants.ProductType.StampBook,
                ShowTotals = true,
            })

            maid:GiveTask(inventoryWindow)
            inventoryWindow:GetWindowFrame().Parent = parent
        end)

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

    -- Custom open tab depending on state
    if PetsController.getTotalHatchableEggs() > 0 then
        tabbedWindow:OpenTab("Pets")
    else
        tabbedWindow:OpenTab("Vehicles")
    end

    ScreenUtil.inDown(tabbedWindow:GetContainer())
    screenGui.Enabled = true
end

function InventoryScreen.close()
    ScreenUtil.outUp(tabbedWindow:GetContainer())
end

return InventoryScreen
