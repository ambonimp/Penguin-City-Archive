local InventoryProductWindow = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Products = require(Paths.Shared.Products.Products)
local ProductController = require(Paths.Client.ProductController)
local Widget = require(Paths.Client.UI.Elements.Widget)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local InventoryWindow = require(Paths.Client.UI.Screens.Inventory.InventoryWindow)

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
            Equip: (value: any) -> nil,
            Unequip: ((value: any) -> nil),
            GetEquipped: () -> { any },
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
        local equippedProducts = data.Equipping and data.Equipping.GetEquipped()
        table.sort(products, function(product0: Products.Product, product1: Products.Product)
            local equipped0 = equippedProducts and table.find(equippedProducts, product0) and true or false
            local equipped1 = equippedProducts and table.find(equippedProducts, product1) and true or false

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

    local populateData: {
        {
            WidgetConstructor: () -> typeof(Widget.diverseWidget()),
            EquipValue: any | nil,
        }
    } =
        {}
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
