local InventoryWindow = {}

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

local GRID_SIZE = Vector2.new(5, 3)

--[[
    data:
    - ProductType: What products to display
    - AddCallback: If passed, will create an "Add" button that will invoke AddCallback
]]
function InventoryWindow.new(icon: string, title: string, data: { ProductType: string?, AddCallback: (() -> nil)? })
    local inventoryWindow = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    --#region Create UI
    local inventoryWindowFrame = Instance.new("Frame")
    inventoryWindowFrame.Name = "inventoryWindowFrame"
    inventoryWindowFrame.BackgroundTransparency = 1
    inventoryWindowFrame.Size = UDim2.fromScale(1, 1)

    local top = Instance.new("Frame")
    top.Name = "top"
    top.BackgroundTransparency = 1
    top.Size = UDim2.fromScale(1, 0.2)

    local topIcon = Instance.new("ImageLabel")
    topIcon.Name = "topIcon"
    topIcon.Image = "rbxassetid://11505043486"
    topIcon.AnchorPoint = Vector2.new(0, 0.5)
    topIcon.BackgroundTransparency = 1
    topIcon.Position = UDim2.fromScale(0.05, 0.5)
    topIcon.Size = UDim2.fromOffset(130, 130)
    topIcon.ScaleType = Enum.ScaleType.Fit
    topIcon.Parent = top

    local topTitle = Instance.new("TextLabel")
    topTitle.Name = "topTitle"
    topTitle.Font = UIConstants.Font
    topTitle.Text = "Hoverboards"
    topTitle.TextColor3 = Color3.fromRGB(38, 71, 118)
    topTitle.TextSize = 80
    topTitle.TextXAlignment = Enum.TextXAlignment.Left
    topTitle.AnchorPoint = Vector2.new(0, 0.5)
    topTitle.BackgroundTransparency = 1
    topTitle.Position = UDim2.new(0.05, 140, 0.5, 0)
    topTitle.Size = UDim2.fromScale(0.4, 1)
    topTitle.Parent = top

    local topPage = Instance.new("TextLabel")
    topPage.Name = "topPage"
    topPage.Font = UIConstants.Font
    topPage.Text = "Page 1/1"
    topPage.TextColor3 = Color3.fromRGB(38, 71, 118)
    topPage.TextSize = 40
    topPage.TextXAlignment = Enum.TextXAlignment.Right
    topPage.TextYAlignment = Enum.TextYAlignment.Bottom
    topPage.AnchorPoint = Vector2.new(1, 1)
    topPage.BackgroundTransparency = 1
    topPage.Position = UDim2.fromScale(0.95, 0.95)
    topPage.Size = UDim2.fromScale(0.4, 0.2)
    topPage.Parent = top

    top.Parent = inventoryWindowFrame

    local divider = Instance.new("Frame")
    divider.Name = "divider"
    divider.AnchorPoint = Vector2.new(0.5, 0)
    divider.BackgroundColor3 = Color3.fromRGB(219, 236, 255)
    divider.Position = UDim2.fromScale(0.5, 0.2)
    divider.Size = UDim2.fromScale(0.9, 0.01)

    local dividerCorner = Instance.new("UICorner")
    dividerCorner.Name = "dividerCorner"
    dividerCorner.CornerRadius = UDim.new(0, 100)
    dividerCorner.Parent = divider

    divider.Parent = inventoryWindowFrame

    local bottom = Instance.new("Frame")
    bottom.Name = "bottom"
    bottom.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bottom.BackgroundTransparency = 1
    bottom.Position = UDim2.fromScale(0, 0.22)
    bottom.Size = UDim2.fromScale(1, 0.77)

    local widgets = Instance.new("Frame")
    widgets.Name = "widgets"
    widgets.AnchorPoint = Vector2.new(0.5, 0.5)
    widgets.BackgroundTransparency = 1
    widgets.Position = UDim2.fromScale(0.5, 0.5)
    widgets.Size = UDim2.new(1, -140, 1, 0)

    local widgetsGridLayout = Instance.new("UIGridLayout")
    widgetsGridLayout.Name = "widgetsGridLayout"
    widgetsGridLayout.CellPadding = UDim2.new()
    widgetsGridLayout.CellSize = UDim2.new(1 / GRID_SIZE.X, -1, 1 / GRID_SIZE.Y, -1)
    widgetsGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    widgetsGridLayout.Parent = widgets

    widgets.Parent = bottom

    local leftArrow = Instance.new("Frame")
    leftArrow.Name = "leftArrow"
    leftArrow.AnchorPoint = Vector2.new(0, 0.5)
    leftArrow.BackgroundTransparency = 1
    leftArrow.Position = UDim2.fromScale(0, 0.5)
    leftArrow.Size = UDim2.fromOffset(60, 100)

    local leftArrowButton = Instance.new("ImageButton")
    leftArrowButton.Name = "leftArrowButton"
    leftArrowButton.Image = "rbxassetid://11252199030"
    leftArrowButton.ScaleType = Enum.ScaleType.Fit
    leftArrowButton.BackgroundTransparency = 1
    leftArrowButton.Size = UDim2.fromScale(1, 1)
    leftArrowButton.Parent = leftArrow

    leftArrow.Parent = bottom

    local rightArrow = Instance.new("Frame")
    rightArrow.Name = "rightArrow"
    rightArrow.AnchorPoint = Vector2.new(1, 0.5)
    rightArrow.BackgroundTransparency = 1
    rightArrow.Position = UDim2.fromScale(1, 0.5)
    rightArrow.Size = UDim2.fromOffset(60, 100)

    local rightArrowButton = Instance.new("ImageButton")
    rightArrowButton.Name = "rightArrowButton"
    rightArrowButton.Image = "rbxassetid://11252175153"
    rightArrowButton.ScaleType = Enum.ScaleType.Fit
    rightArrowButton.BackgroundTransparency = 1
    rightArrowButton.Size = UDim2.fromScale(1, 1)
    rightArrowButton.Parent = rightArrow

    rightArrow.Parent = bottom

    bottom.Parent = inventoryWindowFrame
    --#endregion

    local drawMaid = Maid.new()
    local pageNumber = 1

    local leftArrow = AnimatedButton.new(leftArrowButton)
    local rightArrow = AnimatedButton.new(rightArrowButton)

    topIcon.Image = icon
    topTitle.Text = title

    -- Read Data
    local products: { Products.Product }
    if data.ProductType then
        products = TableUtil.toArray(Products.Products[data.ProductType])
    else
        error("Bad data")
    end

    local addCallback = data.AddCallback

    local totalProductsPerPage = GRID_SIZE.X * GRID_SIZE.Y - (addCallback and 1 or 0) -- -1 for add widget

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function getMaxPageNumber()
        return math.clamp(math.ceil(#products / totalProductsPerPage), 1, math.huge)
    end

    -- Sorts products based on ownership
    local function sortProducts()
        table.sort(products, function(product0: Products.Product, product1: Products.Product)
            local isOwned0 = ProductController.hasProduct(product0)
            local isOwned1 = ProductController.hasProduct(product1)

            if isOwned0 ~= isOwned1 then
                return isOwned0
            end

            return product0.Id < product1.Id
        end)
    end

    local function getHolderFrame(layoutOrder: number)
        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.LayoutOrder = layoutOrder
        holder.Parent = widgets
        return holder
    end

    local function draw()
        drawMaid:Cleanup()

        -- Grab products to show on the current page
        local pageIndexContext = (pageNumber - 1) * totalProductsPerPage
        local visibleProducts: { Products.Product } = {}
        for i = 1 + pageIndexContext, totalProductsPerPage + pageIndexContext do
            local product = products[i]
            if product then
                table.insert(visibleProducts, product)
            else
                break
            end
        end

        -- Add Widget
        if addCallback then
            local holder = getHolderFrame(-1)
            drawMaid:GiveTask(holder)

            local addWidget = Widget.addWidget()
            addWidget:Mount(holder)
            drawMaid:GiveTask(addWidget)
        end

        -- Product Widgets
        for i, product in pairs(visibleProducts) do
            local holder = getHolderFrame(i)
            drawMaid:GiveTask(holder)

            local widget = Widget.diverseWidgetFromProduct(product, true)
            widget:Mount(holder)
            drawMaid:GiveTask(widget)
        end

        -- Arrows
        leftArrowButton.Visible = pageNumber > 1
        rightArrowButton.Visible = pageNumber < getMaxPageNumber()
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function inventoryWindow:GetWindowFrame()
        return inventoryWindowFrame
    end

    function inventoryWindow:Mount(parent: GuiObject)
        inventoryWindowFrame.Parent = parent
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    -- Navigation
    leftArrow.Pressed:Connect(function()
        if pageNumber > 1 then
            pageNumber -= 1
            draw()
        end
    end)
    rightArrow.Pressed:Connect(function()
        if pageNumber + 1 <= getMaxPageNumber() then
            pageNumber += 1
            draw()
        end
    end)

    -- Populate products as widgets
    sortProducts()
    draw()

    return inventoryWindow
end

return InventoryWindow
