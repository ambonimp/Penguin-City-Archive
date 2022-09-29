local KeyboardButton = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local UIConstants = require(Paths.Client.UI.UIConstants)
local Button = require(Paths.Client.UI.Elements.Button)

local BACK_COLOR_FACTOR = 0.75 -- How the color of the back is calculated; lower = more obvious
local SELECT_COLOR_MIN_SAT = 0.05 -- If the saturation value is lower than this, we will manipulate its val instead
local SELECT_COLOR_FACTOR = 0.9 -- How the color of the keyboardButton changes when selected; lower = more obvious
local PRESS_TWEEN_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local RELEASE_TWEEN_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local COLOR_TWEEN_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Linear)
local TEXT_TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local INSTANT_TWEEN = TweenInfo.new(0)
local TEXT_POSITION = UDim2.fromScale(0.5, 0.5)
local TEXT_SIZE = UDim2.fromScale(0.8, 0.8)
local ICON_SIZE = UDim2.fromScale(0.7, 0.7)
local ICON_POSITION = UDim2.fromScale(0.5, 0.48)
local ICON_ANCHOR_POINT = Vector2.new(0.5, 0.5)
local ICON_TEXT_PADDING_SCALE = 0.05
local LEFT_ALIGN_ANCHOR_POINT = Vector2.new(0, 0.5)
local RIGHT_ALIGN_ANCHOR_POINT = Vector2.new(1, 0.5)

KeyboardButton.Defaults = {
    Height = 0.12, -- Dictates size of the "back" of the keyboardButton
    HeightPressed = 0.04, -- Perceived height when the keyboardButton is visually pressed
    CornerRadius = 0.3, -- Severity of corners (0.5 creates circular sides)
    Color = Color3.fromRGB(230, 156, 21),
    TextColor = Color3.fromRGB(255, 255, 255),
    IconColor = Color3.fromRGB(255, 255, 255),
    IconAlign = "Left",
}

-- Applies a UICorner to the passed Instance with the default CornerRadius
local function mountUICorner(instance: GuiObject)
    local uiCorner = instance:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    uiCorner.Parent = instance
    uiCorner.CornerRadius = UDim.new(KeyboardButton.Defaults.CornerRadius, 0)

    return uiCorner
end

function KeyboardButton.new()
    local keyboardButton = Button.new(Instance.new("ImageButton"))

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local color = KeyboardButton.Defaults.Color
    local cornerRadius = KeyboardButton.Defaults.CornerRadius
    local height = KeyboardButton.Defaults.Height
    local heightPressed = KeyboardButton.Defaults.HeightPressed
    local text = ""
    local textColor = KeyboardButton.Defaults.TextColor
    local iconColor = KeyboardButton.Defaults.IconColor
    local iconAlign: "Left" | "Right" = KeyboardButton.Defaults.IconAlign
    local iconImageId = ""

    local imageButton: ImageButton = keyboardButton:GetButtonObject()
    imageButton.AnchorPoint = Vector2.new(0.5, 0)
    imageButton.Position = UDim2.fromScale(0.5, 0)
    imageButton.AutoButtonColor = false
    local imageButtonUICorner = mountUICorner(imageButton)

    local back = Instance.new("Frame")
    back.AnchorPoint = Vector2.new(0.5, 1)
    back.Position = UDim2.fromScale(0.5, 1)
    back.ZIndex = imageButton.ZIndex - 1
    local backUICorner = mountUICorner(back)
    keyboardButton:GetMaid():GiveTask(back)

    local textLabel = Instance.new("TextLabel")
    textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    textLabel.Position = TEXT_POSITION
    textLabel.Size = TEXT_SIZE
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = textColor
    textLabel.Font = UIConstants.Font
    textLabel.TextScaled = true
    textLabel.Parent = imageButton

    local icon: ImageLabel?

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    --!!

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function selectKeyboardButton(skipTween: boolean?)
        -- Visual Feedback
        do
            local tweenInfo = skipTween and INSTANT_TWEEN or COLOR_TWEEN_INFO

            -- Change color of just imageButton
            local currentColor = imageButton.BackgroundColor3
            local h, s, v = currentColor:ToHSV()

            if s >= SELECT_COLOR_MIN_SAT then
                s = s * SELECT_COLOR_FACTOR
            else
                v = v * SELECT_COLOR_FACTOR
            end
            local newColor = Color3.fromHSV(h, s, v)

            TweenUtil.tween(imageButton, tweenInfo, { BackgroundColor3 = newColor })
        end
    end

    local function deselectKeyboardButton(skipTween: boolean?)
        -- Visual Feedback
        do
            -- Cheeky way to revert back to original color
            local oldIsSelected = keyboardButton:IsSelected()
            keyboardButton:_SetSelected(false)

            keyboardButton:SetColor(color, skipTween)

            keyboardButton:_SetSelected(oldIsSelected)
        end
    end

    local function pressKeyboardButton(skipTween: boolean?)
        -- Visual Feedback
        do
            local tweenInfo = skipTween and INSTANT_TWEEN or PRESS_TWEEN_INFO

            local goalPosition = UDim2.fromScale(0.5, height - heightPressed)
            TweenUtil.tween(imageButton, tweenInfo, { Position = goalPosition })
        end
    end

    local function releaseKeyboardButton(skipTween: boolean?)
        -- Visual Feedback
        do
            local tweenInfo = skipTween and INSTANT_TWEEN or RELEASE_TWEEN_INFO

            local goalPosition = UDim2.fromScale(0.5, 0)
            TweenUtil.tween(imageButton, tweenInfo, { Position = goalPosition })
        end
    end

    local function adjustIconAndText()
        -- RETURN: No icon
        if not icon then
            return
        end

        -- Calculate the sizes we're working with here
        local textBounds = textLabel.TextBounds
        local textXScale = textBounds.X / (textLabel.AbsoluteSize.X / textLabel.Size.X.Scale)
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
            textLabel.AnchorPoint = RIGHT_ALIGN_ANCHOR_POINT
        else
            iconXPosition = 0.5 + totalScale / 2
            textXPosition = 0.5 - totalScale / 2

            icon.AnchorPoint = RIGHT_ALIGN_ANCHOR_POINT
            textLabel.AnchorPoint = LEFT_ALIGN_ANCHOR_POINT
        end

        print(
            ("text: %s, text bounds: %.2f, textxscale: %.2f, iconxscale: %.2f, totalscale: %.2f, iconxpos: %.2f, textxpos: %.2f"):format(
                text,
                textBounds.X,
                textXScale,
                iconXScale,
                totalScale,
                iconXPosition,
                textXPosition
            )
        )

        icon.Position = UDim2.new(iconXPosition, 0, ICON_POSITION.Y.Scale, 0)
        textLabel.Position = UDim2.new(textXPosition, 0, ICON_POSITION.Y.Scale, 0)
        textLabel.Size = UDim2.new(textXScale, 0, TEXT_SIZE.Y.Scale, 0)
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function keyboardButton:GetBackgroundFrame()
        return back
    end

    function keyboardButton:GetTextLabel()
        return textLabel
    end

    function keyboardButton:GetIcon()
        return icon
    end

    function keyboardButton:SetColor(newColor: Color3, skipTween: boolean?)
        color = newColor

        if keyboardButton:IsSelected() then
            deselectKeyboardButton(true)
        end

        local tweenInfo = skipTween and INSTANT_TWEEN or COLOR_TWEEN_INFO
        TweenUtil.tween(imageButton, tweenInfo, { BackgroundColor3 = newColor })

        local h, s, v = newColor:ToHSV()
        local backColor = Color3.fromHSV(h, s, v * BACK_COLOR_FACTOR)
        TweenUtil.tween(back, tweenInfo, { BackgroundColor3 = backColor })

        if keyboardButton:IsSelected() then
            selectKeyboardButton(true)
        end

        return self
    end

    function keyboardButton:SetCornerRadius(newRadius: number)
        cornerRadius = newRadius

        imageButtonUICorner.CornerRadius = UDim.new(cornerRadius, 0)
        backUICorner.CornerRadius = UDim.new(cornerRadius, 0)

        return self
    end

    function keyboardButton:SetHeight(newHeight: number?, newHeightPressed: number?)
        height = newHeight or height
        newHeightPressed = newHeightPressed or heightPressed

        imageButton.Size = UDim2.fromScale(1, 1 - height)
        back.Size = UDim2.fromScale(1, 1 - height)

        if self:IsPressed() then
            pressKeyboardButton(true)
        else
            releaseKeyboardButton(true)
        end

        return self
    end

    -- Nicely changes the text displayed on this keyboardButton. Supports UIStroke!
    function keyboardButton:SetText(newText: string, skipTween: boolean?)
        text = newText

        if skipTween then
            textLabel.Text = text
            return self
        end

        local textTransparency = textLabel.TextTransparency
        local textStrokeTransparency = textLabel.TextStrokeTransparency
        local uiStroke = textLabel:FindFirstChildOfClass("UIStroke")
        local uiStrokeTransparency = uiStroke and uiStroke.Transparency

        -- Hide the text changing by fading out/in the text transparency
        local fadeOutTween = TweenUtil.tween(textLabel, TEXT_TWEEN_INFO, { TextTransparency = 1, TextStrokeTransparency = 1 })
        if uiStroke then
            TweenUtil.tween(uiStroke, TEXT_TWEEN_INFO, { Transparency = 1 })
        end

        task.spawn(function()
            if fadeOutTween.PlaybackState == Enum.PlaybackState.Playing then
                fadeOutTween.Completed:Wait()
            end

            textLabel.Text = text
            adjustIconAndText()

            TweenUtil.tween(
                textLabel,
                TEXT_TWEEN_INFO,
                { TextTransparency = textTransparency, TextStrokeTransparency = textStrokeTransparency }
            )
            if uiStroke then
                TweenUtil.tween(uiStroke, TEXT_TWEEN_INFO, { Transparency = uiStrokeTransparency })
            end
        end)

        return self
    end

    function keyboardButton:SetTextColor(newColor: Color3, skipTween: boolean?)
        textColor = newColor

        local tweenInfo = skipTween and INSTANT_TWEEN or COLOR_TWEEN_INFO
        TweenUtil.tween(textLabel, tweenInfo, { TextColor = textColor })

        return self
    end

    function keyboardButton:SetIcon(imageId: string, align: "Left" | "Right"?)
        align = align or "Left"

        -- Create ImageLabel
        if not icon then
            icon = Instance.new("ImageLabel")
            icon.Transparency = 1
            icon.Size = ICON_SIZE
            icon.Position = ICON_POSITION
            icon.AnchorPoint = ICON_ANCHOR_POINT
            icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
            icon.Parent = imageButton

            adjustIconAndText()
        end

        iconAlign = align
        iconImageId = imageId

        icon.Image = iconImageId

        return self
    end

    function keyboardButton:SetIconColor(newColor: Color3, skipTween: boolean?)
        iconColor = newColor

        local tweenInfo = skipTween and INSTANT_TWEEN or COLOR_TWEEN_INFO
        TweenUtil.tween(icon, tweenInfo, { ImageColor3 = iconColor })

        return self
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    keyboardButton.InternalMount:Connect(function(parent: Instance, _hideParent: boolean?)
        back.Parent = parent
    end)
    keyboardButton.InternalPress:Connect(function()
        pressKeyboardButton()
    end)
    keyboardButton.InternalRelease:Connect(function()
        releaseKeyboardButton()
    end)
    keyboardButton.InternalEnter:Connect(function()
        selectKeyboardButton()
    end)
    keyboardButton.InternalLeave:Connect(function()
        deselectKeyboardButton()
    end)

    keyboardButton:SetColor(color, true)
    keyboardButton:SetCornerRadius(cornerRadius)
    keyboardButton:SetHeight(height)

    return keyboardButton
end

return KeyboardButton
