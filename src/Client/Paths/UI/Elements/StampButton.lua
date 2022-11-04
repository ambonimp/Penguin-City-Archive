local StampButton = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local AnimatedButton = require(script.Parent.AnimatedButton)
local Stamps = require(ReplicatedStorage.Shared.Stamps.Stamps)
local UIConstants = require(StarterPlayer.StarterPlayerScripts.Paths.UI.UIConstants)
local Images = require(ReplicatedStorage.Shared.Images.Images)
local StampConstants = require(ReplicatedStorage.Shared.Stamps.StampConstants)
local StampUtil = require(ReplicatedStorage.Shared.Stamps.StampUtil)

export type State = {
    Progress: number?,
}

local COLOR_BLACK = Color3.fromRGB(0, 0, 0)
local VISIBLE_SHINE_TRANSPARENCY = 0.5
local FADE_TRANSPARENCY = 0.7

function StampButton.new(stamp: Stamps.Stamp, state: State?)
    -- Manage State
    state = state or {}
    state.Progress = state.Progress or math.huge

    -- Create Class
    local stampFrame = Instance.new("ImageButton")
    local stampButton = AnimatedButton.new(stampFrame)
    stampButton:SetHoverAnimation(AnimatedButton.Animations.Nod)
    stampButton:SetPressAnimation(AnimatedButton.Animations.Squish)

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    --#region Create UI
    stampFrame.Name = "stampFrame"
    stampFrame.BackgroundTransparency = 1
    stampFrame.Size = UDim2.fromScale(1, 1)

    local pattern = Instance.new("ImageLabel")
    pattern.Name = "pattern"
    pattern.AnchorPoint = Vector2.new(0.5, 0.5)
    pattern.BackgroundTransparency = 1
    pattern.Position = UDim2.fromScale(0.5, 0.5)
    pattern.Size = UDim2.fromScale(0.75, 0.75)
    pattern.SizeConstraint = Enum.SizeConstraint.RelativeYY

    local icon = Instance.new("ImageLabel")
    icon.Name = "icon"
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Position = UDim2.fromScale(0.5, 0.5)
    icon.Size = UDim2.fromScale(1, 1)

    local shine = Instance.new("ImageLabel")
    shine.Name = "shine"
    shine.ImageTransparency = 1
    shine.AnchorPoint = Vector2.new(0.5, 0.5)
    shine.BackgroundTransparency = 1
    shine.Position = UDim2.fromScale(0.5, 0.5)
    shine.Size = UDim2.fromScale(1.25, 1.25)

    local border = Instance.new("ImageLabel")
    border.Name = "border"
    border.AnchorPoint = Vector2.new(0.5, 0.5)
    border.BackgroundTransparency = 1
    border.Position = UDim2.fromScale(0.5, 0.5)
    border.Size = UDim2.fromScale(1, 1)
    border.Parent = shine

    shine.Parent = icon
    icon.Parent = pattern
    pattern.Parent = stampFrame
    --#endregion

    -- Read State
    local stampProgress: number = state.Progress
    local tier = stamp.IsTiered and StampUtil.getTierFromProgress(stamp, stampProgress)
    local doFade = (stamp.IsTiered and tier == nil) or (not stamp.IsTiered and stampProgress < 1)
    local useTier = tier or Stamps.StampTiers[1]

    -- Draw Stamp type images
    pattern.Image = Images.Stamps.Types[stamp.Type].Pattern
    shine.Image = Images.Stamps.Types[stamp.Type].Shine
    border.Image = Images.Stamps.Types[stamp.Type].Border

    -- Draw Stamp
    stampFrame.Name = stamp.Id
    icon.Image = (stamp.IsTiered and stamp.ImageId[useTier]) or stamp.ImageId or ""

    -- Draw difficulty/tier
    if stamp.Difficulty then
        pattern.ImageColor3 = StampConstants.DifficultyColors[stamp.Difficulty]
    elseif stamp.IsTiered then
        pattern.ImageColor3 = StampConstants.TierColors[useTier]
        shine.ImageTransparency = VISIBLE_SHINE_TRANSPARENCY
    end

    -- Fade
    if doFade then
        for _, guiObject: ImageLabel in pairs({ pattern, icon, shine, border }) do
            guiObject.ImageTransparency = guiObject.ImageTransparency + (1 - guiObject.ImageTransparency) / (1 / FADE_TRANSPARENCY)
        end

        local h, s, v = pattern.ImageColor3:ToHSV()
        pattern.ImageColor3 = Color3.fromHSV(h, s, v / 2)
    end

    --!! If no ImageId, add a simple text label (debug)
    if icon.Image == "" then
        local text = stamp.DisplayName
        if stamp.IsTiered then
            text = ("%s (Tiered)"):format(text)
        end

        local textLabel = Instance.new("TextLabel")
        textLabel.TextScaled = true
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = COLOR_BLACK
        textLabel.Text = text
        textLabel.Font = UIConstants.Font
        textLabel.Size = UDim2.fromScale(0.8, 0.8)
        textLabel.Parent = pattern
    end

    return stampButton
end

return StampButton
