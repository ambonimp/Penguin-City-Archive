local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RadialMenu = {}

local UIElement = require(script.Parent.UIElement)
local KeyboardButton = require(script.Parent.KeyboardButton)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)

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
    holderFrame.Size = UDim2.fromScale(1, 1)

    local buttonHolders: { Frame } = {}
    local buttons: { typeof(KeyboardButton.new()) } = {}

    local scale = RadialMenu.Defaults.Scale

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

    function radialMenu:Mount(parent: GuiObject)
        holderFrame.Parent = parent
    end

    -- Returns a KeyboardButton
    function radialMenu:AddButton()
        local button = KeyboardButton.new()
        button:Mount(createButtonHolder())
        table.insert(buttons, button)
        redraw()
        return button
    end

    -- Returns true if removed
    function radialMenu:RemoveButton(button: typeof(KeyboardButton.new()))
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
