local CoinsWindow = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local TitledWindow = require(Paths.Client.UI.Elements.TitledWindow)
local Images = require(Paths.Shared.Images.Images)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local Products = require(Paths.Shared.Products.Products)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local ProductController = require(Paths.Client.ProductController)

type CoinsWindowProduct = {
    Title: string,
    ProductId: string,
}

local function createBuyButton(buyButtonFrame: Frame, product: Products.Product)
    local buyButton = KeyboardButton.new()
    buyButton:SetColor(UIConstants.Colors.Buttons.AvailableGreen)
    buyButton:SetIcon(Images.Icons.Robux, "Left")
    buyButton:SetText(StringUtil.commaValue(product.RobuxData.Cost))
    buyButton:Mount(buyButtonFrame, true)

    buyButton.Pressed:Connect(function()
        ProductController.prompt(product)
    end)
end

local function getBottomTemplate(title: string, product: Products.Product)
    local bottomTemplate = Instance.new("Frame")

    --#region Create UI
    bottomTemplate.Name = "bottomTemplate"
    bottomTemplate.BackgroundTransparency = 1
    bottomTemplate.Size = UDim2.fromScale(0.5, 1)

    local background = Instance.new("Frame")
    background.Name = "background"
    background.AnchorPoint = Vector2.new(0.5, 0.5)
    background.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    background.Position = UDim2.fromScale(0.5, 0.5)
    background.Size = UDim2.new(1, -30, 1, -30)

    local uICorner = Instance.new("UICorner")
    uICorner.Name = "uICorner"
    uICorner.CornerRadius = UDim.new(0, 10)
    uICorner.Parent = background

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "titleLabel"
    titleLabel.Font = UIConstants.Font
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(0, 71, 118)
    titleLabel.TextSize = 50
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.AnchorPoint = Vector2.new(0.5, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.fromScale(0.5, 0)
    titleLabel.Size = UDim2.fromScale(1, 0.2)

    local titleUIStroke = Instance.new("UIStroke")
    titleUIStroke.Name = "titleUIStroke"
    titleUIStroke.Color = Color3.fromRGB(0, 71, 118)
    titleUIStroke.Parent = titleLabel

    titleLabel.Parent = background

    local uIPadding = Instance.new("UIPadding")
    uIPadding.Name = "uIPadding"
    uIPadding.PaddingBottom = UDim.new(0, 10)
    uIPadding.PaddingLeft = UDim.new(0, 10)
    uIPadding.PaddingRight = UDim.new(0, 10)
    uIPadding.PaddingTop = UDim.new(0, 10)
    uIPadding.Parent = background

    local buyButtonFrame = Instance.new("Frame")
    buyButtonFrame.Name = "buyButtonFrame"
    buyButtonFrame.AnchorPoint = Vector2.new(0.5, 1)
    buyButtonFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    buyButtonFrame.Position = UDim2.fromScale(0.5, 1)
    buyButtonFrame.Size = UDim2.fromScale(1, 0.3)
    buyButtonFrame.ZIndex = 3
    buyButtonFrame.Parent = background

    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = "imageLabel"
    imageLabel.Image = product.ImageId or ""
    imageLabel.ImageColor3 = Color3.fromRGB(232, 232, 232)
    imageLabel.ScaleType = Enum.ScaleType.Fit
    imageLabel.AnchorPoint = Vector2.new(1, 1)
    imageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Position = UDim2.new(1, -20, 0.7, 20)
    imageLabel.Size = UDim2.fromOffset(260, 260)
    imageLabel.ZIndex = 2
    imageLabel.Parent = background

    local amountLabel = Instance.new("TextLabel")
    amountLabel.Name = "amountLabel"
    amountLabel.Font = UIConstants.Font
    amountLabel.Text = ("%s Coins"):format(StringUtil.commaValue(ProductUtil.getCoinProductData(product).AddCoins))
    amountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    amountLabel.TextSize = 45
    amountLabel.TextXAlignment = Enum.TextXAlignment.Left
    amountLabel.AnchorPoint = Vector2.new(0.5, 0)
    amountLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    amountLabel.BackgroundTransparency = 1
    amountLabel.Position = UDim2.fromScale(0.5, 0.2)
    amountLabel.Size = UDim2.fromScale(1, 0.2)
    amountLabel.ZIndex = 3

    local amountUIStroke = Instance.new("UIStroke")
    amountUIStroke.Name = "amountUIStroke"
    amountUIStroke.Color = Color3.fromRGB(0, 71, 118)
    amountUIStroke.Thickness = 1.5
    amountUIStroke.Parent = amountLabel

    amountLabel.Parent = background

    background.Parent = bottomTemplate
    --#endregion

    createBuyButton(buyButtonFrame, product)

    return bottomTemplate
end

local function getTopTemplate(title: string, product: Products.Product)
    local topTemplate = Instance.new("Frame")

    --#region Create UI
    topTemplate.Name = "topTemplate"
    topTemplate.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    topTemplate.BackgroundTransparency = 1
    topTemplate.Size = UDim2.fromScale(0.333, 1)

    local background = Instance.new("Frame")
    background.Name = "background"
    background.AnchorPoint = Vector2.new(0.5, 0.5)
    background.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    background.Position = UDim2.fromScale(0.5, 0.5)
    background.Size = UDim2.new(1, -30, 1, -30)

    local uICorner = Instance.new("UICorner")
    uICorner.Name = "uICorner"
    uICorner.CornerRadius = UDim.new(0, 10)
    uICorner.Parent = background

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "titleLabel"
    titleLabel.Font = UIConstants.Font
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(0, 71, 118)
    titleLabel.TextSize = 50
    titleLabel.AnchorPoint = Vector2.new(0.5, 0)
    titleLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.fromScale(0.5, 0)
    titleLabel.Size = UDim2.fromScale(1, 0.2)

    local titleUIStroke = Instance.new("UIStroke")
    titleUIStroke.Name = "titleUIStroke"
    titleUIStroke.Color = Color3.fromRGB(0, 71, 118)
    titleUIStroke.Parent = titleLabel

    titleLabel.Parent = background

    local uIPadding = Instance.new("UIPadding")
    uIPadding.Name = "uIPadding"
    uIPadding.PaddingBottom = UDim.new(0, 10)
    uIPadding.PaddingLeft = UDim.new(0, 10)
    uIPadding.PaddingRight = UDim.new(0, 10)
    uIPadding.PaddingTop = UDim.new(0, 10)
    uIPadding.Parent = background

    local buyButtonFrame = Instance.new("Frame")
    buyButtonFrame.Name = "buyButtonFrame"
    buyButtonFrame.AnchorPoint = Vector2.new(0.5, 1)
    buyButtonFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    buyButtonFrame.Position = UDim2.fromScale(0.5, 1)
    buyButtonFrame.Size = UDim2.fromScale(1, 0.3)
    buyButtonFrame.ZIndex = 3
    buyButtonFrame.Parent = background

    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = "imageLabel"
    imageLabel.Image = product.ImageId or ""
    imageLabel.ImageColor3 = Color3.fromRGB(232, 232, 232)
    imageLabel.ScaleType = Enum.ScaleType.Fit
    imageLabel.AnchorPoint = Vector2.new(0.5, 1)
    imageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Position = UDim2.new(0.5, 0, 0.7, 10)
    imageLabel.Size = UDim2.fromOffset(170, 170)
    imageLabel.ZIndex = 2
    imageLabel.Parent = background

    local amountLabel = Instance.new("TextLabel")
    amountLabel.Name = "amountLabel"
    amountLabel.Font = UIConstants.Font
    amountLabel.Text = ("%s Coins"):format(StringUtil.commaValue(ProductUtil.getCoinProductData(product).AddCoins))
    amountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    amountLabel.TextSize = 45
    amountLabel.TextWrapped = true
    amountLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    amountLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    amountLabel.BackgroundTransparency = 1
    amountLabel.Position = UDim2.fromScale(0.5, 0.55)
    amountLabel.Size = UDim2.fromScale(1, 0.2)
    amountLabel.ZIndex = 3

    local amountUIStroke = Instance.new("UIStroke")
    amountUIStroke.Name = "amountUIStroke"
    amountUIStroke.Color = Color3.fromRGB(0, 71, 118)
    amountUIStroke.Thickness = 1.5
    amountUIStroke.Parent = amountLabel

    amountLabel.Parent = background

    background.Parent = topTemplate
    --#endregion

    createBuyButton(buyButtonFrame, product)

    return topTemplate
end

function CoinsWindow.new()
    local coinsWindow = TitledWindow.new(Images.Coins.Coin, "Coins", "Buy Coins Here!")

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    --#region Create UI
    local container = Instance.new("Frame")
    container.Name = "container"
    container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    container.BackgroundTransparency = 1
    container.Size = UDim2.fromScale(1, 1)

    local containerUIListLayout = Instance.new("UIListLayout")
    containerUIListLayout.Name = "containerUIListLayout"
    containerUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    containerUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    containerUIListLayout.Parent = container

    local top = Instance.new("Frame")
    top.Name = "top"
    top.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    top.BackgroundTransparency = 1
    top.Size = UDim2.fromScale(1, 0.5)

    local topUIListLayout = Instance.new("UIListLayout")
    topUIListLayout.Name = "topUIListLayout"
    topUIListLayout.FillDirection = Enum.FillDirection.Horizontal
    topUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    topUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    topUIListLayout.Parent = top

    top.Parent = container

    local bottom = Instance.new("Frame")
    bottom.Name = "bottom"
    bottom.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bottom.BackgroundTransparency = 1
    bottom.LayoutOrder = 1
    bottom.Size = UDim2.fromScale(1, 0.5)

    local bottomUIListLayout = Instance.new("UIListLayout")
    bottomUIListLayout.Name = "bottomUIListLayout"
    bottomUIListLayout.FillDirection = Enum.FillDirection.Horizontal
    bottomUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    bottomUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bottomUIListLayout.Parent = bottom

    bottom.Parent = container

    local containerUIPadding = Instance.new("UIPadding")
    containerUIPadding.Name = "containerUIPadding"
    containerUIPadding.PaddingBottom = UDim.new(0, 5)
    containerUIPadding.PaddingLeft = UDim.new(0, 20)
    containerUIPadding.PaddingRight = UDim.new(0, 20)
    containerUIPadding.Parent = container
    --#endregion

    -- Create Product Options

    -- Coin Pile
    local coinPileProduct = ProductUtil.getProduct(ProductConstants.ProductType.Coin, "coin_pile")
    local coinPileFrame = getTopTemplate("COIN PILE", coinPileProduct)
    coinPileFrame.LayoutOrder = 1
    coinPileFrame.Parent = top

    -- Coin Bag
    local coinBagProduct = ProductUtil.getProduct(ProductConstants.ProductType.Coin, "coin_bag")
    local coinBagFrame = getTopTemplate("COIN BAG", coinBagProduct)
    coinBagFrame.LayoutOrder = 2
    coinBagFrame.Parent = top

    -- Coin Stack
    local coinStackProduct = ProductUtil.getProduct(ProductConstants.ProductType.Coin, "coin_stack")
    local coinStackFrame = getTopTemplate("COIN STACK", coinStackProduct)
    coinStackFrame.LayoutOrder = 3
    coinStackFrame.Parent = top

    -- Coin Chest
    local coinChestProduct = ProductUtil.getProduct(ProductConstants.ProductType.Coin, "coin_chest")
    local coinChestFrame = getBottomTemplate("COIN CHEST", coinChestProduct)
    coinChestFrame.LayoutOrder = 1
    coinChestFrame.Parent = bottom

    -- Coin Vault
    local coinVaultProduct = ProductUtil.getProduct(ProductConstants.ProductType.Coin, "coin_vault")
    local coinVaultFrame = getBottomTemplate("COIN VAULT", coinVaultProduct)
    coinVaultFrame.LayoutOrder = 2
    coinVaultFrame.Parent = bottom

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    container.Parent = coinsWindow:GetWindowHolder()

    return coinsWindow
end

return CoinsWindow
