local InventoryProductWindow = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Products = require(Paths.Shared.Products.Products)
local UIConstants = require(Paths.Client.UI.UIConstants)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local Maid = require(Paths.Packages.maid)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local ProductController = require(Paths.Client.ProductController)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local Widget = require(Paths.Client.UI.Elements.Widget)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local UIElement = require(Paths.Client.UI.Elements.UIElement)
local InventoryWindow = require(Paths.Client.UI.Screens.Inventory.InventoryWindow)

local GRID_SIZE = Vector2.new(5, 3)
local EQUIPPED_COLOR = Color3.fromRGB(0, 165, 0)

--[[
    data:
    - ProductType: What products to display
    - AddCallback: If passed, will create an "Add" button that will invoke AddCallback
]]
function InventoryProductWindow.new(
    icon: string,
    title: string,
    data: {
        ProductType: string?,
        AddCallback: (() -> nil)?,
        ShowTotals: boolean?,
        Equipping: {
            Equip: (product: Products.Product) -> nil,
            Unequip: (product: Products.Product) -> nil,
            StartEquipped: Products.Product?,
        }?,
    }
)
    data = data or {}
    local inventoryProductWindow = InventoryWindow.new(icon, title, {
        AddCallback = data.AddCallback,
        Equipping = data.Equipping,
    })

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    -- Read Data
    local products: { Products.Product }
    if data.ProductType then
        products = TableUtil.toArray(Products.Products[data.ProductType])
    else
        error("Bad data")
    end

    local showTotals = data.ShowTotals

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    -- Sorts products based on ownership
    local function sortProducts()
        table.sort(products, function(product0: Products.Product, product1: Products.Product)
            local equipped0 = data.Equipping and data.Equipping.StartEquipped == product0
            local equipped1 = data.Equipping and data.Equipping.StartEquipped == product1

            if equipped0 ~= equipped1 then
                return equipped0
            end

            local count0 = ProductController.getProductCount(product0)
            local count1 = ProductController.getProductCount(product1)

            if count0 ~= count1 then
                return count0 > count1
            end

            return product0.Id < product1.Id
        end)
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    -- Populate
    sortProducts()

    local populateData: { {
        WidgetConstructor: () -> typeof(Widget.diverseWidget()),
        EquipValue: any | nil,
    } } = {}
    for _, product in pairs(products) do
        local entry = {
            WidgetConstructor = function()
                return Widget.diverseWidgetFromProduct(product, { VerifyOwnership = true, ShowTotals = showTotals })
            end,
            EquipValue = product,
        }
        table.insert(populateData, entry)
    end
    inventoryProductWindow:Populate(populateData)

    return inventoryProductWindow
end

return InventoryProductWindow
