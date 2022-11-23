local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RadialMenu = {}

local UIElement = require(script.Parent.UIElement)
local KeyboardButton = require(script.Parent.KeyboardButton)
local Button = require(script.Parent.Button)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local Maid = require(ReplicatedStorage.Packages.maid)
local TweenUtil = require(ReplicatedStorage.Shared.Utils.TweenUtil)
local Promise = require(ReplicatedStorage.Packages.promise)

local OPEN_TWEEN_INFO = TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local CLOSE_TWEEN_INFO = TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

RadialMenu.Defaults = {
    Scale = 0.3,
}

function RadialMenu.new()
    local radialMenu = UIElement.new()

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local holderFrame = Instance.new("Frame")
    holderFrame.BackgroundTransparency = 1
    holderFrame.Size = UDim2.fromScale(0.9, 0.9)
    holderFrame.Position = UDim2.fromScale(0.5, 0.5)
    holderFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    holderFrame.Visible = false

    local buttonHolders: { Frame } = {}
    local buttons: { typeof(KeyboardButton.new()) } = {}

    local scale = RadialMenu.Defaults.Scale
    local isOpen = false

    local animationMaid = Maid.new()
    radialMenu:GetMaid():GiveTask(animationMaid)

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function resizeButtonHolders()
        -- Resize button holders
        for _, buttonHolder in pairs(buttonHolders) do
            buttonHolder.Size = UDim2.fromScale(scale, scale)
        end
    end

    -- Repositions all of our buttons
    local function redraw()
        local totalButtons = #buttons
        -- RETURN: No buttons
        if totalButtons == 0 then
            return
        end

        animationMaid:Cleanup()

        resizeButtonHolders()

        -- EDGE CASE: Center button
        if totalButtons == 1 then
            local buttonHolder = buttonHolders[1]
            buttonHolder.Position = UDim2.fromScale(0.5, 0.5)
            buttonHolder.AnchorPoint = Vector2.new(0.5, 0.5)
            return
        end

        -- Position in circle
        local theta = 360 / totalButtons
        for i = 1, totalButtons do
            local angle = theta * (i - 1)
            local unitX = math.sin(math.rad(angle))
            local unitY = math.cos(math.rad(angle))

            local anchorPoint = Vector2.new(MathUtil.map(unitX, -1, 1, 0, 1), MathUtil.map(unitY, -1, 1, 1, 0))
            local position = UDim2.fromScale(MathUtil.map(unitX, -1, 1, 0, 1), MathUtil.map(unitY, -1, 1, 1, 0))

            local buttonHolder = buttonHolders[i]
            buttonHolder.AnchorPoint = anchorPoint
            buttonHolder.Position = position
        end
    end

    local function createButtonHolder()
        local frame = Instance.new("Frame")
        frame.BackgroundTransparency = 1
        frame.Parent = holderFrame
        table.insert(buttonHolders, frame)
        return frame
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function radialMenu:Open()
        -- RETURN: Already open
        if isOpen then
            return Promise.resolve()
        end
        isOpen = true

        redraw()
        animationMaid:Cleanup()

        -- Tween buttons to their positions
        for _, button in pairs(buttons) do
            local buttonHolder: typeof(createButtonHolder()) = button:GetButtonObject().Parent
            local size = buttonHolder.Size
            local position = buttonHolder.Position
            local anchorPoint = buttonHolder.AnchorPoint

            buttonHolder.Size = UDim2.fromScale(0, 0)
            buttonHolder.Position = UDim2.fromScale(0.5, 0.5)
            buttonHolder.AnchorPoint = Vector2.new(0.5, 0.5)

            local tween = TweenUtil.tween(buttonHolder, OPEN_TWEEN_INFO, {
                Size = size,
                Position = position,
                AnchorPoint = anchorPoint,
            })
            animationMaid:GiveTask(tween)
        end

        holderFrame.Visible = true

        local tweenPromise = Promise.delay(OPEN_TWEEN_INFO.Time)
        animationMaid:GiveTask(function()
            tweenPromise:cancel()
        end)

        return tweenPromise
    end

    function radialMenu:Close()
        -- RETURN: Not open
        if not isOpen then
            return Promise.resolve()
        end
        isOpen = false

        animationMaid:Cleanup()

        -- Tween buttons to center positions
        for _, button in pairs(buttons) do
            local buttonHolder: typeof(createButtonHolder()) = button:GetButtonObject().Parent

            local tween = TweenUtil.tween(buttonHolder, CLOSE_TWEEN_INFO, {
                Size = UDim2.fromScale(0, 0),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
            })
            animationMaid:GiveTask(tween)
        end

        local tweenPromise = Promise.delay(CLOSE_TWEEN_INFO.Time)
        animationMaid:GiveTask(function()
            tweenPromise:cancel()
        end)

        return tweenPromise:andThen(function()
            holderFrame.Visible = false
        end)
    end

    function radialMenu:Mount(parent: GuiObject)
        holderFrame.Parent = parent
    end

    -- Returns a KeyboardButton
    function radialMenu:AddButton(button: Button.Button?)
        button = button or KeyboardButton.new()
        button:Mount(createButtonHolder())
        table.insert(buttons, button)
        redraw()

        button.Pressed:Connect(function()
            radialMenu:Close()
        end)

        return button
    end

    -- Returns true if removed
    function radialMenu:RemoveButton(button: Button.Button)
        local index = table.find(buttons, button)
        if index then
            buttons[index]:Destroy()
            buttonHolders[index]:Destroy()

            table.remove(buttons, index)
            table.remove(buttonHolders, index)

            redraw()
            return true
        end
        return false
    end

    function radialMenu:SetScale(newScale: number)
        scale = newScale
        resizeButtonHolders()
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    radialMenu:GetMaid():GiveTask(function()
        holderFrame:Destroy()
        for _, button in pairs(buttons) do
            button:Destroy()
        end
    end)

    return radialMenu
end

return RadialMenu
