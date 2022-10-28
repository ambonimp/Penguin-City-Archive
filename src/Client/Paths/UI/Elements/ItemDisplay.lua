local ItemDisplay = {}

local StarterPlayer = game:GetService("StarterPlayer")
local UIConstants = require(StarterPlayer.StarterPlayerScripts.Paths.UI.UIConstants)
local Button = require(script.Parent.Button)

local TEXT_POSITION = UDim2.fromScale(0.5, 0.5)
local TEXT_SIZE = UDim2.fromScale(0.95, 0.95)
local ICON_SIZE = UDim2.fromScale(0.9, 0.9)
local ICON_POSITION = UDim2.fromScale(0.5, 0.52)
local ICON_ANCHOR_POINT = Vector2.new(0.5, 0.5)
local ICON_TEXT_PADDING_SCALE = 0.025
local LEFT_ALIGN_ANCHOR_POINT = Vector2.new(0, 0.5)
local RIGHT_ALIGN_ANCHOR_POINT = Vector2.new(1, 0.5)
local CENTER_ALIGN_ANCHOR_POINT = Vector2.new(0.5, 0.5)

ItemDisplay.Defaults = {
    IconAlign = "Left",
}

function ItemDisplay.new()
    local detailedWidget = Instance.new("ImageButton")
    local itemDisplay = Button.new(detailedWidget)

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local iconAlign: "Left" | "Right" = ItemDisplay.Defaults.IconAlign

    --#region Create UI
    detailedWidget.Name = "detailedWidget"
    detailedWidget.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    detailedWidget.BackgroundTransparency = 1
    detailedWidget.Image = ""
    detailedWidget.Size = UDim2.fromScale(1, 1)

    local back = Instance.new("Frame")
    back.Name = "back"
    back.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    back.BorderSizePixel = 0
    back.Size = UDim2.fromScale(1, 1)

    local uICorner = Instance.new("UICorner")
    uICorner.Name = "uICorner"
    uICorner.Parent = back

    local uIStroke = Instance.new("UIStroke")
    uIStroke.Name = "uIStroke"
    uIStroke.Thickness = 4
    uIStroke.Parent = back

    local bottom = Instance.new("Frame")
    bottom.Name = "bottom"
    bottom.AnchorPoint = Vector2.new(0, 1)
    bottom.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bottom.BackgroundTransparency = 1
    bottom.Position = UDim2.fromScale(0, 1)
    bottom.Size = UDim2.new(1, 0, 0, 49)

    local corners = Instance.new("Frame")
    corners.Name = "corners"
    corners.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    corners.Size = UDim2.fromScale(1, 1)

    local uICorner1 = Instance.new("UICorner")
    uICorner1.Name = "uICorner1"
    uICorner1.Parent = corners

    corners.Parent = bottom

    local flat = Instance.new("Frame")
    flat.Name = "flat"
    flat.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    flat.BorderSizePixel = 0
    flat.Size = UDim2.fromScale(1, 0.5)
    flat.Parent = bottom

    local contents = Instance.new("Frame")
    contents.Name = "contents"
    contents.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    contents.BackgroundTransparency = 1
    contents.Size = UDim2.fromScale(1, 1)
    contents.ZIndex = 2
    contents.Parent = bottom

    local bottomLabel = Instance.new("TextLabel")
    bottomLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    bottomLabel.Position = TEXT_POSITION
    bottomLabel.Size = TEXT_SIZE
    bottomLabel.BackgroundTransparency = 1
    bottomLabel.Text = "Bottom"
    bottomLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    bottomLabel.Font = UIConstants.Font
    bottomLabel.TextScaled = true
    bottomLabel.Parent = contents

    bottom.Parent = back

    local topLeft = Instance.new("Frame")
    topLeft.Name = "topLeft"
    topLeft.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    topLeft.BackgroundTransparency = 1
    topLeft.Size = UDim2.fromOffset(125, 39)

    local corners1 = Instance.new("Frame")
    corners1.Name = "corners1"
    corners1.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    corners1.Size = UDim2.fromScale(1, 1)

    local uICorner2 = Instance.new("UICorner")
    uICorner2.Name = "uICorner2"
    uICorner2.Parent = corners1

    corners1.Parent = topLeft

    local rightFlat = Instance.new("Frame")
    rightFlat.Name = "rightFlat"
    rightFlat.AnchorPoint = Vector2.new(1, 0)
    rightFlat.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    rightFlat.BorderSizePixel = 0
    rightFlat.Position = UDim2.fromScale(1, 0)
    rightFlat.Size = UDim2.fromScale(0.5, 0.5)
    rightFlat.Parent = topLeft

    local leftFlat = Instance.new("Frame")
    leftFlat.Name = "leftFlat"
    leftFlat.AnchorPoint = Vector2.new(0, 1)
    leftFlat.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    leftFlat.BorderSizePixel = 0
    leftFlat.Position = UDim2.fromScale(0, 1)
    leftFlat.Size = UDim2.fromScale(0.5, 0.5)
    leftFlat.Parent = topLeft

    local contents1 = Instance.new("Frame")
    contents1.Name = "contents1"
    contents1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    contents1.BackgroundTransparency = 1
    contents1.Size = UDim2.fromScale(1, 1)
    contents1.ZIndex = 2
    contents1.Parent = topLeft

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "titleLabel"
    titleLabel.Font = UIConstants.Font
    titleLabel.Text = "Title"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.TextWrapped = true
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.fromScale(1, 1)
    titleLabel.Parent = contents1

    topLeft.Parent = back

    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = "imageLabel"
    imageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Position = UDim2.new(0, 0, 0, 38)
    imageLabel.Size = UDim2.new(1, 0, 1, -93)
    imageLabel.ScaleType = Enum.ScaleType.Fit
    imageLabel.Parent = back

    back.Parent = detailedWidget

    local uIPadding = Instance.new("UIPadding")
    uIPadding.Name = "uIPadding"
    uIPadding.PaddingBottom = UDim.new(0, 2)
    uIPadding.PaddingLeft = UDim.new(0, 2)
    uIPadding.PaddingRight = UDim.new(0, 2)
    uIPadding.PaddingTop = UDim.new(0, 2)
    uIPadding.Parent = detailedWidget

    local overlay = Instance.new("Frame")
    overlay.Name = "overlay"
    overlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.Visible = false
    overlay.Parent = back

    local uICorner3 = Instance.new("UICorner")
    uICorner3.Name = "uICorner"
    uICorner3.Parent = overlay

    local checkmark = Instance.new("ImageLabel")
    checkmark.Name = "checkmark"
    checkmark.Image = "rbxassetid://11374895711"
    checkmark.ScaleType = Enum.ScaleType.Fit
    checkmark.AnchorPoint = Vector2.new(0.5, 0.5)
    checkmark.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    checkmark.BackgroundTransparency = 1
    checkmark.Position = UDim2.fromScale(0.5, 0.5)
    checkmark.Size = UDim2.fromScale(0.5, 0.5)
    checkmark.Parent = overlay
    --#endregion
    itemDisplay:GetMaid():GiveTask(detailedWidget)

    local icon: ImageLabel
    local colorObjects: { UIStroke | GuiObject } = { uIStroke, corners, flat, corners1, rightFlat, leftFlat, overlay }

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function adjustIconAndText()
        -- RETURN: No icon
        if not icon then
            return
        end

        local hasText = bottomLabel.Text ~= ""
        local hasImage = icon.Image ~= ""

        if hasText and hasImage then
            -- Calculate the sizes we're working with here
            local textBounds = bottomLabel.TextBounds
            local textXScale = textBounds.X / (bottomLabel.AbsoluteSize.X / bottomLabel.Size.X.Scale)
            local iconXScale = icon.AbsoluteSize.X / icon.Parent.AbsoluteSize.X
            local totalScale = textXScale + iconXScale + ICON_TEXT_PADDING_SCALE

            -- Scale back text label if too large
            local overshotBy = math.max(0, totalScale - TEXT_SIZE.X.Scale)
            textXScale -= overshotBy
            totalScale = math.min(totalScale, TEXT_SIZE.X.Scale)

            -- Calculate where to position icon and text
            local iconXPosition: number
            local textXPosition: number
            if iconAlign == "Left" then
                iconXPosition = 0.5 - totalScale / 2
                textXPosition = 0.5 + totalScale / 2

                icon.AnchorPoint = LEFT_ALIGN_ANCHOR_POINT
                bottomLabel.AnchorPoint = RIGHT_ALIGN_ANCHOR_POINT
            else
                iconXPosition = 0.5 + totalScale / 2
                textXPosition = 0.5 - totalScale / 2

                icon.AnchorPoint = RIGHT_ALIGN_ANCHOR_POINT
                bottomLabel.AnchorPoint = LEFT_ALIGN_ANCHOR_POINT
            end

            icon.Position = UDim2.new(iconXPosition, 0, ICON_POSITION.Y.Scale, 0)
            bottomLabel.Position = UDim2.new(textXPosition, 0, TEXT_POSITION.Y.Scale, 0)
            bottomLabel.Size = UDim2.new(textXScale, 0, TEXT_SIZE.Y.Scale, 0)
        else
            -- Then just center what we do have
            if hasText then
                bottomLabel.AnchorPoint = CENTER_ALIGN_ANCHOR_POINT
                bottomLabel.Position = TEXT_POSITION
            else
                icon.AnchorPoint = CENTER_ALIGN_ANCHOR_POINT
                icon.Position = ICON_POSITION
            end
        end
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function itemDisplay:SetTitle(title: string)
        titleLabel.Text = title

        return self
    end

    function itemDisplay:SetText(text: string)
        bottomLabel.Text = text
        adjustIconAndText()

        return self
    end

    function itemDisplay:SetTextIcon(imageId: string, align: "Left" | "Right"?)
        align = align or "Left"

        -- Create ImageLabel
        if not icon then
            icon = Instance.new("ImageLabel")
            icon.Transparency = 1
            icon.Size = ICON_SIZE
            icon.Position = ICON_POSITION
            icon.AnchorPoint = ICON_ANCHOR_POINT
            icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
            icon.ScaleType = Enum.ScaleType.Fit
            icon.Parent = contents
        end

        iconAlign = align

        icon.Image = imageId
        adjustIconAndText()

        return self
    end

    function itemDisplay:SetTextColor(color: Color3)
        bottomLabel.TextColor3 = color
        titleLabel.TextColor3 = color
    end

    function itemDisplay:SetImage(imageId: string)
        imageLabel.Image = imageId
    end

    function itemDisplay:SetBorderColor(color: Color3)
        for _, object in pairs(colorObjects) do
            if object:IsA("UIStroke") then
                object.Color = color
            elseif object:IsA("GuiObject") then
                object.BackgroundColor3 = color
            else
                error(object.ClassName)
            end
        end
    end

    function itemDisplay:SetBackgroundColor(color: Color3)
        back.BackgroundColor3 = color
    end

    function itemDisplay:SetOverlay(overlayType: "Completed" | nil)
        overlay.Visible = overlayType and true or false
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    --todo

    return itemDisplay
end

return ItemDisplay
