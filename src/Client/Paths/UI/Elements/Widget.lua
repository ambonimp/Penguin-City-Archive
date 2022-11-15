--[[
    Cheeky file for widgets that we may display in e.g., SelectionPanel, or Inventory
]]
local Widget = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local Maid = require(Paths.Packages.maid)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local Products = require(Paths.Shared.Products.Products)
local ProductController = require(Paths.Client.ProductController)
local Images = require(Paths.Shared.Images.Images)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)
local TimeUtil = require(Paths.Shared.Utils.TimeUtil)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local PetConstants = require(Paths.Shared.Pets.PetConstants)
local PetUtils = require(Paths.Shared.Pets.PetUtils)

local FADE_TRANSPARENCY = 0.5
local ADD_BUTTON_SIZE = UDim2.fromScale(0.75, 0.75)
local ICON_PROPERTIES = {
    WITH_TEXT = {
        Position = UDim2.fromScale(0.5, 0.4),
        Size = UDim2.fromScale(0.75, 0.75),
    },
    SOLO = {
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.9, 0.9),
    },
}
local PET_EGG_HSV_RANGE = {
    INCUBATING = {
        H = 15,
        S = 255,
        V = 240,
    },
    READY = {
        H = 80,
        S = 255,
        V = 210,
    },
}
local HATCH_BACKGROUND_COLOR = Color3.fromRGB(202, 235, 188)
local COLOR_WHITE = Color3.fromRGB(255, 255, 255)

Widget.Defaults = {
    TextColor = Color3.fromRGB(255, 255, 255),
    TextStrokeColor = Color3.fromRGB(38, 71, 118),
    ImageColor = Color3.fromRGB(255, 255, 255),
}

function Widget.addWidget()
    local widget = Widget.diverseWidget()

    widget:SetIcon(Images.Icons.Add, UIConstants.Colors.Buttons.AvailableGreen)
    widget:GetButtonObject().Size = ADD_BUTTON_SIZE

    return widget
end

function Widget.diverseWidgetFromProduct(product: Products.Product, state: { VerifyOwnership: boolean?, ShowTotals: boolean? }?)
    local widget = Widget.diverseWidget()
    state = state or {}

    -- Populate Widget
    widget:SetText(product.DisplayName)

    local model = ProductUtil.getModel(product)
    if model then
        widget:SetViewport(model)
    else
        widget:SetIcon(product.ImageId, product.ImageColor)
    end

    -- Handle widget being used for purchases + showing if owned
    if state.VerifyOwnership then
        local isOwned = ProductController.hasProduct(product) or ProductUtil.isFree(product)
        if not isOwned then
            widget:SetFade(true)
            widget:SetPrice(product.CoinData and product.CoinData.Cost)

            local purchaseMaid = Maid.new()
            widget:GetMaid():GiveTask(purchaseMaid)

            purchaseMaid:GiveTask(widget.Pressed:Connect(function()
                ProductController.prompt(product)
            end))

            purchaseMaid:GiveTask(ProductController.ProductAdded:Connect(function(addedProduct: Products.Product, _amount: number)
                if product == addedProduct then
                    widget:SetFade(false)
                    widget:SetPrice()
                end
            end))
        end
    end

    -- Show total owned
    if state.ShowTotals then
        local function updateNumberTag()
            local productCount = ProductController.getProductCount(product)
            if productCount > 0 then
                widget:SetNumberTag(productCount)
            else
                widget:SetNumberTag(nil)
            end
        end

        local numberTagMaid = Maid.new()
        widget:GetMaid():GiveTask(numberTagMaid)

        numberTagMaid:GiveTask(ProductController.ProductAdded:Connect(function(addedProduct: Products.Product, _amount: number)
            if product == addedProduct then
                updateNumberTag()
            end
        end))
        updateNumberTag()
    end

    return widget
end

--[[
    `hatchTime` must be straight from data
]]
function Widget.diverseWidgetFromEgg(petEggName: string, petEggDataIndex: string)
    -- Circular Dependencies
    local PetsController = require(Paths.Client.Pets.PetsController)

    local widget = Widget.diverseWidget()
    local product = ProductUtil.getPetEggProduct(petEggName, "Incubating")

    -- Egg
    if product.ImageId then
        widget:SetIcon(product.ImageId, product.ImageColor)
    else
        local model = ProductUtil.getModel(product)
        if model then
            widget:SetViewport(model)
        end
    end

    -- Timer
    local doLoop = true
    task.spawn(function()
        while doLoop do
            local hatchesIn = PetsController.getHatchTime(petEggName, petEggDataIndex)

            -- Update Text
            if hatchesIn > 0 then
                widget:SetText(TimeUtil.formatRelativeTime(hatchesIn))
                widget:SetBackgroundColor(nil)
            else
                widget:SetText("HATCH!")
                widget:SetBackgroundColor(HATCH_BACKGROUND_COLOR)
            end

            -- Update color based on progress (red to green)
            local hatchProgress = 1 - math.clamp(hatchesIn / PetConstants.PetEggs[petEggName].HatchTime, 0, 1)
            local strokeColor = Color3.fromHSV(
                MathUtil.lerp(PET_EGG_HSV_RANGE.INCUBATING.H / 255, PET_EGG_HSV_RANGE.READY.H / 255, hatchProgress),
                MathUtil.lerp(PET_EGG_HSV_RANGE.INCUBATING.S / 255, PET_EGG_HSV_RANGE.READY.S / 255, hatchProgress),
                MathUtil.lerp(PET_EGG_HSV_RANGE.INCUBATING.V / 255, PET_EGG_HSV_RANGE.READY.V / 255, hatchProgress)
            )
            widget:SetTextColor(nil, strokeColor)

            task.wait(1)
        end
    end)
    widget:GetMaid():GiveTask(function()
        doLoop = false
    end)

    return widget
end

function Widget.diverseWidgetFromPetTuple(petTuple: PetConstants.PetTuple)
    local widget = Widget.diverseWidget()
    local model = PetUtils.getModel(petTuple.PetType, petTuple.PetVariant)

    widget:SetText(("%s %s"):format(StringUtil.getFriendlyString(petTuple.PetVariant), StringUtil.getFriendlyString(petTuple.PetType)))
    widget:SetViewport(model)

    return widget
end

function Widget.diverseWidgetFromPetData(petData: PetConstants.PetData)
    local widget = Widget.diverseWidgetFromPetTuple(petData.PetTuple)

    widget:SetText(petData.Name)

    return widget
end

function Widget.diverseWidget()
    local widget = AnimatedButton.new(Instance.new("ImageButton"))
    widget:SetHoverAnimation(AnimatedButton.Animations.Nod)
    widget:SetPressAnimation(nil)

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    --#region Create UI
    local diverseWidget = Instance.new("Frame")
    diverseWidget.Name = "diverseWidget"
    diverseWidget.BackgroundTransparency = 1
    diverseWidget.Size = UDim2.fromScale(1, 1)

    local imageButton = widget:GetButtonObject()
    imageButton.Name = "imageButton"
    imageButton.AnchorPoint = Vector2.new(0.5, 0.5)
    imageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    imageButton.BorderSizePixel = 0
    imageButton.Position = UDim2.fromScale(0.5, 0.5)
    imageButton.Size = UDim2.fromScale(0.9, 0.9)

    local uICorner = Instance.new("UICorner")
    uICorner.Name = "uICorner"
    uICorner.Parent = imageButton

    local outlineStroke = Instance.new("UIStroke")
    outlineStroke.Name = "outlineStroke"
    outlineStroke.Color = Color3.fromRGB(59, 148, 0)
    outlineStroke.Thickness = 6
    outlineStroke.Enabled = false
    outlineStroke.Parent = imageButton

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "textLabel"
    textLabel.Font = UIConstants.Font
    textLabel.Text = ""
    textLabel.TextColor3 = Widget.Defaults.TextColor
    textLabel.TextScaled = true
    textLabel.AnchorPoint = Vector2.new(0.5, 1)
    textLabel.BackgroundTransparency = 1
    textLabel.Position = UDim2.fromScale(0.5, 1)
    textLabel.Size = UDim2.fromScale(0.95, 0.25)

    local textLabelStroke = Instance.new("UIStroke")
    textLabelStroke.Name = "textLabelStroke"
    textLabelStroke.Color = Widget.Defaults.TextStrokeColor
    textLabelStroke.Thickness = 2
    textLabelStroke.Parent = textLabel

    textLabel.Parent = imageButton

    local numberTagFrame = Instance.new("Frame")
    numberTagFrame.Name = "numberTagFrame"
    numberTagFrame.AnchorPoint = Vector2.new(0.7, 0.3)
    numberTagFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    numberTagFrame.Position = UDim2.fromScale(1, 0)
    numberTagFrame.Size = UDim2.fromOffset(50, 50)
    numberTagFrame.Visible = false

    local numberTagUICorner = Instance.new("UICorner")
    numberTagUICorner.Name = "numberTagUICorner"
    numberTagUICorner.CornerRadius = UDim.new(0, 100)
    numberTagUICorner.Parent = numberTagFrame

    local numberTagUIStroke = Instance.new("UIStroke")
    numberTagUIStroke.Name = "numberTagUIStroke"
    numberTagUIStroke.Color = Color3.fromRGB(26, 49, 81)
    numberTagUIStroke.Thickness = 4
    numberTagUIStroke.Transparency = 0.5
    numberTagUIStroke.Parent = numberTagFrame

    local numberTagLabel = Instance.new("TextLabel")
    numberTagLabel.Name = "numberTagLabel"
    numberTagLabel.Font = UIConstants.Font
    numberTagLabel.Text = "1"
    numberTagLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    numberTagLabel.TextScaled = true
    numberTagLabel.TextSize = 30
    numberTagLabel.TextStrokeTransparency = 0.5
    numberTagLabel.TextWrapped = true
    numberTagLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    numberTagLabel.BackgroundTransparency = 1
    numberTagLabel.Position = UDim2.fromScale(0.5, 0.5)
    numberTagLabel.Size = UDim2.fromScale(0.8, 0.8)

    local numberTagLabelUIStroke = Instance.new("UIStroke")
    numberTagLabelUIStroke.Name = "numberTagLabelUIStroke"
    numberTagLabelUIStroke.Color = Color3.fromRGB(38, 71, 118)
    numberTagLabelUIStroke.Thickness = 2
    numberTagLabelUIStroke.Parent = numberTagLabel

    numberTagLabel.Parent = numberTagFrame
    numberTagFrame.Parent = imageButton

    local closeButtonFrame = Instance.new("Frame")
    closeButtonFrame.Name = "closeButtonFrame"
    closeButtonFrame.AnchorPoint = Vector2.new(0.7, 0.3)
    closeButtonFrame.BackgroundTransparency = 1
    closeButtonFrame.Position = UDim2.fromScale(1, 0)
    closeButtonFrame.Size = UDim2.fromOffset(50, 50)
    closeButtonFrame.Parent = imageButton

    local icon = Instance.new("Frame")
    icon.Name = "icon"
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Position = UDim2.fromScale(0.5, 0.4)
    icon.Size = UDim2.fromScale(0.75, 0.75)

    local iconImageLabel = Instance.new("ImageLabel")
    iconImageLabel.Name = "iconImageLabel"
    iconImageLabel.Image = "rbxassetid://11152369533"
    iconImageLabel.ScaleType = Enum.ScaleType.Fit
    iconImageLabel.BackgroundTransparency = 1
    iconImageLabel.Size = UDim2.fromScale(1, 1)
    iconImageLabel.Parent = icon

    local viewportFrame = Instance.new("ViewportFrame")
    viewportFrame.Name = "viewportFrame"
    viewportFrame.BackgroundTransparency = 1
    viewportFrame.Size = UDim2.fromScale(1, 1)
    viewportFrame.Parent = icon

    icon.Parent = imageButton

    local priceFrame = Instance.new("Frame")
    priceFrame.Name = "priceFrame"
    priceFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    priceFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    priceFrame.Position = UDim2.fromScale(0.225, 0.1)
    priceFrame.Rotation = -10
    priceFrame.Size = UDim2.fromScale(0.6, 0.2)
    priceFrame.Visible = false

    local priceUICorner = Instance.new("UICorner")
    priceUICorner.Name = "priceUICorner"
    priceUICorner.Parent = priceFrame

    local priceUIStroke = Instance.new("UIStroke")
    priceUIStroke.Name = "priceUIStroke"
    priceUIStroke.Color = Color3.fromRGB(26, 49, 81)
    priceUIStroke.Thickness = 4
    priceUIStroke.Transparency = 0.5
    priceUIStroke.Parent = priceFrame

    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "priceLabel"
    priceLabel.Font = UIConstants.Font
    priceLabel.Text = "$300"
    priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    priceLabel.TextScaled = true
    priceLabel.TextSize = 30
    priceLabel.TextWrapped = true
    priceLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Position = UDim2.fromScale(0.5, 0.5)
    priceLabel.Size = UDim2.fromScale(0.8, 0.8)

    local uIStroke3 = Instance.new("UIStroke")
    uIStroke3.Name = "uIStroke3"
    uIStroke3.Color = Color3.fromRGB(38, 71, 118)
    uIStroke3.Thickness = 2
    uIStroke3.Parent = priceLabel

    priceLabel.Parent = priceFrame
    priceFrame.Parent = imageButton
    imageButton.Parent = diverseWidget
    --#endregion

    local closeCallbackMaid = Maid.new()

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function adjustIconAndText()
        if textLabel.Text == "" then
            icon.Size = ICON_PROPERTIES.SOLO.Size
            icon.Position = ICON_PROPERTIES.SOLO.Position
        else
            icon.Size = ICON_PROPERTIES.WITH_TEXT.Size
            icon.Position = ICON_PROPERTIES.WITH_TEXT.Position
        end
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function widget:SetPrice(price: number?)
        if price then
            priceFrame.Visible = true
            priceLabel.Text = ("$%s"):format(StringUtil.commaValue(price))
        else
            priceFrame.Visible = false
        end
    end

    function widget:SetText(text: string?)
        textLabel.Text = text or ""
        adjustIconAndText()
    end

    function widget:SetTextColor(textColor: Color3?, strokeColor: Color3?)
        textLabel.TextColor3 = textColor or Widget.Defaults.TextColor
        textLabelStroke.Color = strokeColor or Widget.Defaults.TextStrokeColor
    end

    function widget:SetIcon(image: string?, imageColor: Color3?)
        iconImageLabel.Visible = true
        viewportFrame.Visible = false

        iconImageLabel.Image = image or ""
        iconImageLabel.ImageColor3 = imageColor or Widget.Defaults.ImageColor
    end

    function widget:SetViewport(model: Model)
        iconImageLabel.Visible = false
        viewportFrame.Visible = true

        CameraUtil.lookAtModelInViewport(viewportFrame, model)
    end

    function widget:SetBackgroundColor(color: Color3?)
        imageButton.BackgroundColor3 = color or COLOR_WHITE
    end

    function widget:SetOutline(color: Color3?)
        if color then
            outlineStroke.Enabled = true
            outlineStroke.Color = color
        else
            outlineStroke.Enabled = false
        end
    end

    -- Will enable the close button, which then gets removed when its clicked and calls callback
    function widget:SetCloseCallback(callback: (() -> nil)?)
        closeCallbackMaid:Cleanup()

        if callback then
            local closeButton = ExitButton.new()
            closeButton:Mount(closeButtonFrame, true)
            closeCallbackMaid:GiveTask(closeButton)

            closeButton.Pressed:Connect(function()
                closeCallbackMaid:Cleanup()
                callback()
            end)
        end
    end

    function widget:SetFade(doFade: boolean)
        local transparency = doFade and FADE_TRANSPARENCY or 0

        iconImageLabel.ImageTransparency = transparency
        viewportFrame.ImageTransparency = transparency
        imageButton.BackgroundTransparency = transparency
        textLabel.TextTransparency = transparency
        textLabelStroke.Transparency = transparency
        priceFrame.BackgroundTransparency = transparency
        priceLabel.TextStrokeTransparency = transparency
        priceUIStroke.Transparency = transparency
        numberTagFrame.BackgroundTransparency = transparency
        numberTagUIStroke.Transparency = transparency
        numberTagLabelUIStroke.Transparency = transparency
        numberTagLabel.TextTransparency = transparency
    end

    function widget:SetNumberTag(number: number?)
        if number then
            numberTagFrame.Visible = true
            numberTagLabel.Text = tostring(number)
        else
            numberTagFrame.Visible = false
        end
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    adjustIconAndText()

    return widget
end

return Widget
