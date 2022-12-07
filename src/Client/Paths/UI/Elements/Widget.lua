--[[
    Cheeky file for widgets that we may display in e.g., SelectionPanel, or Inventory
]]
local Widget = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local Maid = require(Paths.Packages.maid)
local Products = require(Paths.Shared.Products.Products)
local ProductController = require(Paths.Client.ProductController)
local Images = require(Paths.Shared.Images.Images)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local CameraUtil = require(Paths.Client.Utils.CameraUtil)
local TimeUtil = require(Paths.Shared.Utils.TimeUtil)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local PetConstants = require(Paths.Shared.Pets.PetConstants)
local PetUtils = require(Paths.Shared.Pets.PetUtils)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)

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

local templates: Folder = Paths.Templates

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

            purchaseMaid:GiveTask(ProductController.ProductAdded:Connect(function(addedProduct: Products.Product, amount: number)
                local isNowOwned = product == addedProduct and amount > 0
                if isNowOwned then
                    widget:SetFade(false)
                    widget:SetPrice()
                    purchaseMaid:Cleanup()
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
    local PetController = require(Paths.Client.Pets.PetController)

    local widget = Widget.diverseWidget()
    local product = ProductUtil.getPetEggProduct(petEggName)

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
            local hatchesIn = PetController.getHatchTime(petEggName, petEggDataIndex)

            -- Update Text
            if hatchesIn > 0 then
                widget:SetText(TimeUtil.formatRelativeTime(math.ceil(hatchesIn)))
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

function Widget.diverseWidgetFromHouseObject(category: string, objectKey: string)
    local product = ProductUtil.getHouseObjectProduct(category, objectKey)
    local widget = Widget.diverseWidgetFromProduct(product, { VerifyOwnership = true, ShowTotals = true })
    local assets = ReplicatedStorage.Assets.Housing
    local model = assets.Furniture[objectKey]:Clone()

    widget:GetGuiObject().Size = UDim2.new(0, 250, 1, 0)
    widget:SetViewport(model)

    return widget
end

function Widget.diverseWidgetFromHouseColor(colorName: string, color: Color3)
    local product = ProductUtil.getHouseColorProduct(colorName, color)
    local widget = Widget.diverseWidgetFromProduct(product, { VerifyOwnership = true, ShowTotals = false })

    local ui = widget:GetGuiObject()
    ui.ZIndex = 50

    widget:SetIconColor(color)

    local selected = templates.Housing.ColorSelected:Clone()
    selected.Parent = ui.imageButton.icon.iconImageLabel

    ui.imageButton.icon.iconImageLabel.ZIndex += 1
    selected.ZIndex = ui.imageButton.icon.iconImageLabel.ZIndex - 1

    function widget:SetSelected(on: boolean)
        selected.Visible = on or false
    end

    return widget
end

function Widget.diverseWidgetFromPetDataIndex(petDataIndex: string)
    -- Circular Dependencies
    local PetController = require(Paths.Client.Pets.PetController)

    local petData = PetController.getPet(petDataIndex)
    local widget = Widget.diverseWidgetFromPetData(petData)

    widget:GetMaid():GiveTask(PetController.PetNameChanged:Connect(function(petName: string, somePetDataIndex: string)
        if somePetDataIndex == petDataIndex then
            widget:SetText(petName)
        end
    end))

    return widget
end

function Widget.diverseWidget()
    local widget = AnimatedButton.new(Instance.new("ImageButton"))
    widget:SetHoverAnimation(nil)
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
    outlineStroke.Thickness = 10
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
    imageButton.Parent = diverseWidget
    --#endregion

    local priceFrame: Frame | nil
    local priceLabel: TextLabel | nil
    local priceUIStroke: UIStroke | nil

    local cornerMaid = Maid.new()
    local cornerFade: (() -> nil) | nil

    local transparency = 0

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

    function widget:DisableIcon()
        textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        textLabel.Position = UDim2.fromScale(0.5, 0.5)
        iconImageLabel.Visible = false
    end

    function widget:EnableIcon()
        iconImageLabel.Visible = true
        textLabel.AnchorPoint = Vector2.new(0.5, 1)
        textLabel.Position = UDim2.fromScale(0.5, 1)
    end

    function widget:SetIconColor(imageColor: Color3?)
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

    function widget:SetPrice(price: number?)
        if price then
            if not priceFrame then
                --#region Create UI
                priceFrame = Instance.new("Frame")
                priceFrame.Name = "priceFrame"
                priceFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                priceFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                priceFrame.Position = UDim2.fromScale(0.225, 0.1)
                priceFrame.Rotation = -10
                priceFrame.Size = UDim2.fromScale(0.6, 0.2)

                local priceUICorner = Instance.new("UICorner")
                priceUICorner.Name = "priceUICorner"
                priceUICorner.Parent = priceFrame

                priceUIStroke = Instance.new("UIStroke")
                priceUIStroke.Name = "priceUIStroke"
                priceUIStroke.Color = Color3.fromRGB(26, 49, 81)
                priceUIStroke.Thickness = 4
                priceUIStroke.Transparency = 0.5
                priceUIStroke.Parent = priceFrame

                priceLabel = Instance.new("TextLabel")
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
                --#endregion
            end
            priceLabel.Text = ("$%s"):format(StringUtil.commaValue(price))
        elseif priceFrame then
            priceFrame:Destroy()
            priceLabel:Destroy()
            priceUIStroke:Destroy()
            priceFrame = nil
        end
    end

    function widget:SetFade(doFade: boolean)
        transparency = doFade and FADE_TRANSPARENCY or 0

        iconImageLabel.ImageTransparency = transparency
        viewportFrame.ImageTransparency = transparency
        imageButton.BackgroundTransparency = transparency
        textLabel.TextTransparency = transparency
        textLabelStroke.Transparency = transparency

        if priceFrame then
            priceFrame.BackgroundTransparency = transparency
            priceLabel.TextStrokeTransparency = transparency
            priceUIStroke.Transparency = transparency
        end

        if cornerFade then
            cornerFade()
        end
    end

    function widget:SetNumberTag(number: number?)
        cornerMaid:Cleanup()

        if number then
            --#region Create UI
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
            --#endregion

            -- Populate + Cleanup
            numberTagFrame.Visible = true
            numberTagLabel.Text = tostring(number)

            cornerMaid:GiveTask(function()
                numberTagFrame:Destroy()
                cornerFade = nil
            end)

            -- Setup Fading
            cornerFade = function()
                numberTagFrame.BackgroundTransparency = transparency
                numberTagUIStroke.Transparency = transparency
                numberTagLabelUIStroke.Transparency = transparency
                numberTagLabel.TextTransparency = transparency
            end
            cornerFade()
        end
    end

    function widget:SetCornerButton(button: typeof(KeyboardButton.new())?)
        cornerMaid:Cleanup()

        if button then
            --#region Create UI
            local cornerButtonFrame = Instance.new("Frame")
            cornerButtonFrame.Name = "cornerButtonFrame"
            cornerButtonFrame.AnchorPoint = Vector2.new(0.7, 0.3)
            cornerButtonFrame.BackgroundTransparency = 1
            cornerButtonFrame.Position = UDim2.fromScale(1, 0)
            cornerButtonFrame.Size = UDim2.fromOffset(50, 50)
            cornerButtonFrame.ZIndex = 2

            cornerButtonFrame.Parent = imageButton
            --#endregion

            button:GetButtonObject().Size = UDim2.fromScale(1, 1)
            button:Mount(cornerButtonFrame)

            cornerMaid:GiveTask(function()
                cornerButtonFrame:Destroy()
                button:Destroy()
            end)
        end
    end

    function widget:GetGuiObject()
        return diverseWidget
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    adjustIconAndText()

    return widget
end

return Widget
