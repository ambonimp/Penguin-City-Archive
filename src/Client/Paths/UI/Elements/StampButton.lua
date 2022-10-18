local StampButton = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimatedButton = require(script.Parent.AnimatedButton)
local Stamps = require(ReplicatedStorage.Shared.Stamps.Stamps)

local BACKGROUND_TRANSPARENCY = 0.9
local COLOR = Color3.fromRGB(255, 255, 255)
local UI_STROKE_THICKNESS = 6

function StampButton.new(stamp: Stamps.Stamp)
    local imageButton = Instance.new("ImageButton")
    local stampButton = AnimatedButton.fromGuiObject(imageButton)
    stampButton:SetPressAnimation(AnimatedButton.Defaults.PressAnimation)
    stampButton:SetHoverAnimation(AnimatedButton.Defaults.HoverAnimation)

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    imageButton.Name = stamp.Id
    imageButton.Image = stamp.ImageId
    imageButton.BackgroundTransparency = BACKGROUND_TRANSPARENCY
    imageButton.BackgroundColor3 = COLOR
    imageButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
    imageButton.Size = UDim2.fromScale(1, 1)

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(1, 0)
    uiCorner.Parent = imageButton

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = COLOR
    uiStroke.Thickness = UI_STROKE_THICKNESS
    uiStroke.Parent = imageButton

    --!! If no ImageId, add a simple text label (debug)
    if stamp.ImageId == "" then
        print("text")
        local textLabel = Instance.new("TextLabel")
        textLabel.TextScaled = true
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = COLOR
        textLabel.Text = stamp.DisplayName
        textLabel.Size = UDim2.fromScale(1, 1)
        textLabel.Parent = imageButton
    end

    return stampButton
end

return StampButton
