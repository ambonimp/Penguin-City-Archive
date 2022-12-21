local InventoryScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Shared.Maid)
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
local ZoneController = require(Paths.Client.Zones.ZoneController)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ToolController = require(Paths.Client.Tools.ToolController)
local ToolUtil = require(Paths.Shared.Tools.ToolUtil)

local screenGui: ScreenGui
local openMaid = Maid.new()
local tabbedWindow: typeof(TabbedWindow.new())

local petShopZone = ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, "PetShop")
local hoverboardShopZone = ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, "HoverboardShop")

function InventoryScreen.Init()
    -- Setup Tabbed Window
    do
        -- Create
        screenGui = Instance.new("ScreenGui")
        screenGui.Enabled = false
        screenGui.Name = "InventoryScreen"
        screenGui.Parent = Ui

        tabbedWindow = TabbedWindow.new(UIConstants.States.Inventory)
        tabbedWindow:Mount(screenGui)

        -- Close
        tabbedWindow.ClosePressed:Connect(function()
            UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.Inventory)
        end)
    end

    -- Tabs
    do
        -- -- Vehicles
        -- tabbedWindow:AddTab("Vehicles", Images.Icons.Hoverboard)
        -- tabbedWindow:SetWindowConstructor("Vehicles", function(parent, maid)
        --     local inventoryWindow = InventoryProductWindow.new(Images.Icons.Hoverboard, "Vehicles", {
        --         ProductType = ProductConstants.ProductType.Vehicle,
        --         AddCallback = function()
        --             UIController.getStateMachine():Remove(UIConstants.States.Inventory)
        --             ZoneController.teleportToRoomRequest(hoverboardShopZone)
        --         end,
        --         Equipping = {
        --             Equip = function(product: Products.Product)
        --                 local vehicleName = ProductUtil.getVehicleProductData(product).VehicleName
        --                 VehicleController.mountRequest(vehicleName)
        --             end,
        --             Unequip = function(_product: Products.Product)
        --                 VehicleController.dismountRequest()
        --             end,
        --             StartEquipped = VehicleController.getCurrentVehicleName()
        --                 and ProductUtil.getVehicleProduct(VehicleController.getCurrentVehicleName()),
        --         },
        --     })

        --     maid:GiveTask(inventoryWindow)
        --     inventoryWindow:Mount(parent)
        -- end)

        -- Tools
        tabbedWindow:AddTab("Tools", Images.Icons.Toy)
        tabbedWindow:SetWindowConstructor("Tools", function(parent, maid)
            local inventoryWindow = InventoryProductWindow.new(Images.Icons.Toy, "Tools", {
                ProductType = ProductConstants.ProductType.Tool,
                Equipping = {
                    Equip = function(product: Products.Product)
                        local toolData = ProductUtil.getToolProductData(product)
                        ToolController.holster(ToolUtil.tool(toolData.CategoryName, toolData.ToolId))
                    end,
                    Unequip = function(product: Products.Product)
                        local toolData = ProductUtil.getToolProductData(product)
                        ToolController.unholster(ToolUtil.tool(toolData.CategoryName, toolData.ToolId))
                    end,
                    GetEquipped = function()
                        return ToolController.getHolsteredProducts()
                    end,
                },
            })

            maid:GiveTask(inventoryWindow)
            inventoryWindow:Mount(parent)
        end)

        -- Pets
        tabbedWindow:AddTab("Pets", Images.Icons.Pets)
        tabbedWindow:SetWindowConstructor("Pets", function(parent, maid)
            local inventoryWindow = InventoryPetsWindow.new(Images.Icons.Pets, "Pets", {
                AddCallback = function()
                    UIController.getStateMachine():Remove(UIConstants.States.Inventory)
                    ZoneController.teleportToRoomRequest(petShopZone, {
                        TravelMethod = ZoneConstants.TravelMethod.Inventory,
                    })
                end,
            })

            maid:GiveTask(inventoryWindow)
            inventoryWindow:Mount(parent)
        end)

        --TODO
        -- tabbedWindow:AddTab("Food", Images.Icons.Food)
        -- tabbedWindow:AddTab("Toys", Images.Icons.Toy)
        -- tabbedWindow:AddTab("Roleplay", Images.Icons.Roleplay)
    end

    -- Register UIState
    UIController.registerStateScreenCallbacks(UIConstants.States.Inventory, {
        Boot = InventoryScreen.boot,
        Shutdown = nil,
        Maximize = InventoryScreen.maximize,
        Minimize = InventoryScreen.minimize,
    })
end

function InventoryScreen.boot()
    openMaid:Cleanup()

    -- Custom open tab depending on state
    if PetController.getTotalHatchableEggs() > 0 then
        tabbedWindow:OpenTab("Pets")
        return
    end

    tabbedWindow:OpenTab("Tools")
end

function InventoryScreen.minimize()
    ScreenUtil.outUp(tabbedWindow:GetContainer())
end

function InventoryScreen.maximize()
    ScreenUtil.inDown(tabbedWindow:GetContainer())
    screenGui.Enabled = true
end

return InventoryScreen
