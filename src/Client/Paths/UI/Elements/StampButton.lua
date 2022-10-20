local StampButton = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local AnimatedButton = require(script.Parent.AnimatedButton)
local Stamps = require(ReplicatedStorage.Shared.Stamps.Stamps)
local UIConstants = require(StarterPlayer.StarterPlayerScripts.Paths.UI.UIConstants)

local BACKGROUND_TRANSPARENCY = 0.8
local COLOR_WHITE = Color3.fromRGB(255, 255, 255)
local COLOR_BLACK = Color3.fromRGB(0, 0, 0)
local UI_STROKE_THICKNESS = 6

function StampButton.new(stamp: Stamps.Stamp)
    local imageButton = Instance.new("ImageButton")
    local stampButton = AnimatedButton.new(imageButton)
    stampButton:SetPressAnimation(AnimatedButton.Defaults.PressAnimation)
    stampButton:SetHoverAnimation(AnimatedButton.Defaults.HoverAnimation)

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    imageButton.Name = stamp.Id
    imageButton.Image = stamp.ImageId
    imageButton.BackgroundTransparency = BACKGROUND_TRANSPARENCY
    imageButton.BackgroundColor3 = COLOR_WHITE
    imageButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
    imageButton.Size = UDim2.fromScale(1, 1)

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(1, 0)
    uiCorner.Parent = imageButton

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = COLOR_WHITE
    uiStroke.Thickness = UI_STROKE_THICKNESS
    uiStroke.Parent = imageButton

    --!! If no ImageId, add a simple text label (debug)
    if stamp.ImageId == "" then
        local textLabel = Instance.new("TextLabel")
        textLabel.TextScaled = true
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = COLOR_BLACK
        textLabel.Text = stamp.DisplayName
        textLabel.Font = UIConstants.Font
        textLabel.Size = UDim2.fromScale(1, 1)
        textLabel.Parent = imageButton
    end

    return stampButton
end

return StampButton
