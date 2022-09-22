local Button = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIElement = Paths.Modules.UIElement
local TweenUtil = Paths.Modules.TweenUntil

local BACK_COLOR_FACTOR = 0.75 -- How the color of the back is calculated; lower = more obvious
local SELECT_COLOR_MIN_SAT = 0.05 -- If the saturation value is lower than this, we will manipulate its val instead
local SELECT_COLOR_FACTOR = 0.9 -- How the color of the button changes when selected; lower = more obvious
local PRESS_TWEEN_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local RELEASE_TWEEN_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local COLOR_TWEEN_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Linear)
local INSTANT_TWEEN = TweenInfo.new(0)

Button.Defaults = {
    Height = 0.12, -- Dictates size of the "back" of the button
    HeightPressed = 0.04, -- Perceived height when the button is visually pressed
    CornerRadius = 0.3, -- Severity of corners (0.5 creates circular sides)
    Color = Color3.fromRGB(255, 255, 255),
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
    -- Members
    -------------------------------------------------------------------------------

    local isSelected = false
    local isPressed = false

    local color = Button.Defaults.Color
    local cornerRadius = Button.Defaults.CornerRadius
    local height = Button.Defaults.Height
    local heightPressed = Button.Defaults.HeightPressed

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

    button.Pressed = Paths.Modules.Signal.new()

    -------------------------------------------------------------------------------
    -- Methods
    -------------------------------------------------------------------------------

    -- Visually selects the button
    local function selectButton(skipTween: boolean?)
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

    -- Inverse of selectButton()
    local function deselectButton(skipTween: boolean?)
        -- Cheeky way to revert back to original color
        local oldIsSelected = isSelected
        isSelected = false

        button:SetColor(color, skipTween)

        isSelected = oldIsSelected
    end

    -- Visually presses the button
    local function pressButton(skipTween: boolean?)
        local tweenInfo = skipTween and INSTANT_TWEEN or PRESS_TWEEN_INFO

        local goalPosition = UDim2.fromScale(0.5, height - heightPressed)
        TweenUtil.tween(imageButton, tweenInfo, { Position = goalPosition })
    end

    -- Inverse of pressButton()
    local function releaseButton(skipTween: boolean?)
        local tweenInfo = skipTween and INSTANT_TWEEN or RELEASE_TWEEN_INFO

        local goalPosition = UDim2.fromScale(0.5, 0)
        TweenUtil.tween(imageButton, tweenInfo, { Position = goalPosition })
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

    function button:IsPressed()
        return isPressed
    end

    function button:IsSelected()
        return isSelected
    end

    function button:SetColor(newColor: Color3, skipTween: boolean)
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
