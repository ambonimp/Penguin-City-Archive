local NotificationIcon = {}

local UIUtil = require(script.Parent.Parent.Utils.UIUtil)
local UIConstants = require(script.Parent.Parent.UIConstants)
local UIElement = require(script.Parent.UIElement)

function NotificationIcon.new()
    local notificationIcon = UIElement.new()

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    --#region Create UI
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "notificationFrame"
    notificationFrame.AnchorPoint = Vector2.new(1, 0)
    notificationFrame.BackgroundColor3 = Color3.fromRGB(220, 0, 0)
    notificationFrame.BackgroundTransparency = 0.1
    notificationFrame.Position = UDim2.fromScale(1, 0)
    notificationFrame.Size = UDim2.fromOffset(35, 35)
    notificationIcon:GetMaid():GiveTask(notificationFrame)

    local uICorner = Instance.new("UICorner")
    uICorner.Name = "uICorner"
    uICorner.CornerRadius = UDim.new(1, 0)
    uICorner.Parent = notificationFrame

    local uIStroke = Instance.new("UIStroke")
    uIStroke.Name = "uIStroke"
    uIStroke.Thickness = 3
    uIStroke.Transparency = 0.2
    uIStroke.Parent = notificationFrame

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "textLabel"
    textLabel.Font = UIConstants.Font
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 28
    textLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.fromScale(1, 1)
    textLabel.Parent = notificationFrame
    --#endregion

    local notificationNumber = 0

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function notificationIcon:SetVisible(isVisible: boolean)
        notificationFrame.Visible = isVisible
    end

    function notificationIcon:Mount(parent: GuiObject, anchorPoint: Vector2)
        notificationFrame.Parent = parent
        UIUtil.offsetZIndex(notificationFrame, parent.ZIndex)

        notificationFrame.AnchorPoint = anchorPoint
        notificationFrame.Position = UDim2.fromScale(anchorPoint.X, anchorPoint.Y)
    end

    function notificationIcon:SetNumber(newNumber: number)
        notificationNumber = newNumber

        textLabel.Text = tostring(notificationNumber)

        -- Hide if there is no number
        notificationIcon:SetVisible(not (notificationNumber == 0))
    end

    function notificationIcon:GetNumber()
        return notificationNumber
    end

    function notificationIcon:IncrementNumber(add: number)
        notificationIcon:SetNumber(math.clamp(notificationNumber + add, 0, math.huge))
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    notificationIcon:SetNumber(0)

    return notificationIcon
end

return NotificationIcon
