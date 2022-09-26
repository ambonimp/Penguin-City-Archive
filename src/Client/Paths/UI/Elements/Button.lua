local Button = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIElement = require(Paths.Client.UI.Elements.UIElement)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local UIConstants = require(Paths.Client.UI.UIConstants)
local Sound = require(Paths.Shared.Sound)
local Signal = require(Paths.Shared.Signal)

local BACK_COLOR_FACTOR = 0.75 -- How the color of the back is calculated; lower = more obvious
local SELECT_COLOR_MIN_SAT = 0.05 -- If the saturation value is lower than this, we will manipulate its val instead
local SELECT_COLOR_FACTOR = 0.9 -- How the color of the button changes when selected; lower = more obvious
local PRESS_TWEEN_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local RELEASE_TWEEN_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local COLOR_TWEEN_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Linear)
local TEXT_TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local INSTANT_TWEEN = TweenInfo.new(0)

Button.Defaults = {
    Height = 0.12, -- Dictates size of the "back" of the button
    HeightPressed = 0.04, -- Perceived height when the button is visually pressed
    CornerRadius = 0.3, -- Severity of corners (0.5 creates circular sides)
    Color = Color3.fromRGB(230, 156, 21),
    TextColor = Color3.fromRGB(255, 255, 255),
}

-- Applies a UICorner to the passed Instance with the default CornerRadius
local function mountUICorner(instance: GuiObject)
    local uiCorner = instance:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    uiCorner.Parent = instance
    uiCorner.CornerRadius = UDim.new(Button.Defaults.CornerRadius, 0)

    return uiCorner
end

function Button.new()
    local button = UIElement.new()

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local isSelected = false
    local isPressed = false

    local color = Button.Defaults.Color
    local cornerRadius = Button.Defaults.CornerRadius
    local height = Button.Defaults.Height
    local heightPressed = Button.Defaults.HeightPressed
    local text = ""
    local textColor = Button.Defaults.TextColor

    local imageButton = Instance.new("ImageButton")
    imageButton.AnchorPoint = Vector2.new(0.5, 0)
    imageButton.Position = UDim2.fromScale(0.5, 0)
    imageButton.AutoButtonColor = false
    local imageButtonUICorner = mountUICorner(imageButton)
    button:GetMaid():GiveTask(imageButton)

    local back = Instance.new("Frame")
    back.AnchorPoint = Vector2.new(0.5, 1)
    back.Position = UDim2.fromScale(0.5, 1)
    back.ZIndex = imageButton.ZIndex - 1
    local backUICorner = mountUICorner(back)
    button:GetMaid():GiveTask(back)

    local textLabel = Instance.new("TextLabel")
    textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    textLabel.Position = UDim2.fromScale(0.5, 0.5)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = textColor
    textLabel.Font = UIConstants.Font
    textLabel.TextScaled = true
    textLabel.Size = UDim2.fromScale(0.9, 0.9)
    textLabel.Parent = imageButton

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    button.Pressed = Signal.new()

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function selectButton(skipTween: boolean?)
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

        -- Audio Feedback
        do
            Sound.play("ButtonHover")
        end
    end

    local function deselectButton(skipTween: boolean?)
        -- Visual Feedback
        do
            -- Cheeky way to revert back to original color
            local oldIsSelected = isSelected
            isSelected = false

            button:SetColor(color, skipTween)

            isSelected = oldIsSelected
        end
    end

    local function pressButton(skipTween: boolean?)
        -- Visual Feedback
        do
            local tweenInfo = skipTween and INSTANT_TWEEN or PRESS_TWEEN_INFO

            local goalPosition = UDim2.fromScale(0.5, height - heightPressed)
            TweenUtil.tween(imageButton, tweenInfo, { Position = goalPosition })
        end

        -- Audio Feedback
        do
            Sound.play("ButtonPress")
        end
    end

    local function releaseButton(skipTween: boolean?)
        -- Visual Feedback
        do
            local tweenInfo = skipTween and INSTANT_TWEEN or RELEASE_TWEEN_INFO

            local goalPosition = UDim2.fromScale(0.5, 0)
            TweenUtil.tween(imageButton, tweenInfo, { Position = goalPosition })
        end

        -- Audio Feedback
        do
            Sound.play("ButtonRelease")
        end
    end

    local function mouseDown()
        -- RETURN: Already pressed?
        if isPressed then
            return
        end
        isPressed = true

        pressButton()
    end

    local function mouseUp()
        -- RETURN: Was never pressed?
        if not isPressed then
            return
        end
        isPressed = false

        releaseButton()
    end

    local function mouseEnter()
        -- RETURN: Already selected?
        if isSelected then
            return
        end
        isSelected = true

        selectButton()
    end

    local function mouseLeave()
        -- RETURN: Was never selected?
        if not isSelected then
            return
        end
        isSelected = false

        deselectButton()

        -- Simulate us stopping the pressing of the button (Roblox doesn't detect MouseButton1Up when not hovering over the button)
        mouseUp()
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function button:GetImageButton()
        return imageButton
    end

    function button:GetBackgroundFrame()
        return back
    end

    function button:GetTextLabel()
        return textLabel
    end

    function button:IsPressed()
        return isPressed
    end

    function button:IsSelected()
        return isSelected
    end

    function button:SetColor(newColor: Color3, skipTween: boolean?)
        color = newColor

        if isSelected then
            deselectButton(true)
        end

        local tweenInfo = skipTween and INSTANT_TWEEN or COLOR_TWEEN_INFO
        TweenUtil.tween(imageButton, tweenInfo, { BackgroundColor3 = newColor })

        local h, s, v = newColor:ToHSV()
        local backColor = Color3.fromHSV(h, s, v * BACK_COLOR_FACTOR)
        TweenUtil.tween(back, tweenInfo, { BackgroundColor3 = backColor })

        if isSelected then
            selectButton(true)
        end

        return self
    end

    function button:SetCornerRadius(newRadius: number)
        cornerRadius = newRadius

        imageButtonUICorner.CornerRadius = UDim.new(cornerRadius, 0)
        backUICorner.CornerRadius = UDim.new(cornerRadius, 0)

        return self
    end

    function button:SetHeight(newHeight: number?, newHeightPressed: number?)
        height = newHeight or height
        newHeightPressed = newHeightPressed or heightPressed

        imageButton.Size = UDim2.fromScale(1, 1 - height)
        back.Size = UDim2.fromScale(1, 1 - height)

        if self:IsPressed() then
            pressButton(true)
        else
            releaseButton(true)
        end

        return self
    end

    function button:Mount(parent: GuiObject, hideInstance: boolean?)
        imageButton.Parent = parent
        back.Parent = parent

        if hideInstance then
            parent.Transparency = 1
        end

        return self
    end

    -- Nicely changes the text displayed on this button. Supports UIStroke!
    function button:SetText(newText: string, skipTween: boolean?)
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

    function button:SetTextColor(newColor: Color3, skipTween: boolean?)
        textColor = newColor

        local tweenInfo = skipTween and INSTANT_TWEEN or COLOR_TWEEN_INFO
        TweenUtil.tween(textLabel, tweenInfo, { TextColor = textColor })

        return self
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    button:GetMaid():GiveTask(imageButton.MouseEnter:Connect(function()
        mouseEnter()
    end))
    button:GetMaid():GiveTask(imageButton.MouseLeave:Connect(function()
        mouseLeave()
    end))
    button:GetMaid():GiveTask(imageButton.MouseButton1Down:Connect(function()
        mouseDown()
    end))
    button:GetMaid():GiveTask(imageButton.MouseButton1Up:Connect(function()
        -- Check before firing, as edge cases can exist (see mouseLeave())
        if isPressed then
            button.Pressed:Fire()
        end

        mouseUp()
    end))

    button:SetColor(color, true)
    button:SetCornerRadius(cornerRadius)
    button:SetHeight(height)

    return button
end

return Button
