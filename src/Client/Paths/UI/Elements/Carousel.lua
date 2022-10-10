--[[
    Essentially a scrolling frame with buttons that help you navigate it
]]
local Carousel = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage.Shared
local Signal = require(Shared.Signal)
local UDimUtil = require(Shared.Utils.UDimUtil)
local Elements = script.Parent
local Element = require(Elements.UIElement)
local KeyboardButton = require(Elements.KeyboardButton)
local UIScaleController: typeof(require(script.Parent.Parent.Scaling.UIScaleController))
type Button = typeof(KeyboardButton.new())

local NAVIGATOR_PADDING = UDim2.fromScale(0, 0.01)
local NAVIGATOR_DISABLED_COLOR = Color3.fromRGB(169, 169, 169)
local SCROLL_PREV_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SCROLL_NEXT_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local IS_PLAYING = RunService:IsRunning()

Carousel.Defaults = {
    NavigatorSize = 10,
    ChildPadding = 10,
    NavigatorColor = KeyboardButton.Defaults.Color,
    TabSortOrder = Enum.SortOrder.LayoutOrder,
}

function Carousel.new()
    local carousel = Element.new()

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------
    local scrollDb: boolean
    local navigatorColor: Color3

    local childPadding: number
    local children: { Instance } = {}

    local prevNavigatorContainer: Frame
    local nextNavigatorContainer: Frame

    local prevNavigator: Button
    local nextNavigator: Button

    local list: ScrollingFrame = Instance.new("ScrollingFrame")
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.CanvasSize = UDim2.fromScale(0, 0)
    list.ScrollingDirection = Enum.ScrollingDirection.Y
    list.ElasticBehavior = Enum.ElasticBehavior.Never
    list.ScrollBarThickness = 0
    list.ScrollBarImageTransparency = 1
    list.AnchorPoint = Vector2.new(0.5, 0.5)
    list.Position = UDim2.fromScale(0.5, 0.5)

    local listLayout: UIListLayout = Instance.new("UIListLayout")
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    listLayout.Parent = list

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------
    carousel.InternalMount = Signal.new()

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------
    local function createNavigatorContainer(position: UDim2, anchorPoint: Vector2): Frame
        local container = Instance.new("Frame")
        container.AnchorPoint = anchorPoint
        container.Position = position
        return container
    end

    local function createNavigator(): Button
        return KeyboardButton.new()
    end

    local function toggleNavigator(navigator: Button, enabled: boolean)
        navigator:SetColor(if enabled then navigatorColor else NAVIGATOR_DISABLED_COLOR, true)
    end

    local function isPrevNavigatorEnabled(): boolean
        local enabled = list.CanvasPosition.Y ~= 0
        toggleNavigator(prevNavigator, enabled)

        return enabled
    end

    local function isNextNavigatorEnabled(): boolean
        local enabled = list.CanvasPosition.Y ~= list.AbsoluteCanvasSize.Y - list.AbsoluteSize.Y
        toggleNavigator(nextNavigator, enabled)

        return enabled
    end

    local function updateNavigatorsEnabled()
        if listLayout.AbsoluteContentSize.Y <= list.AbsoluteSize.Y then
            toggleNavigator(prevNavigator, false)
            toggleNavigator(nextNavigator, false)
        else
            isNextNavigatorEnabled()
            isPrevNavigatorEnabled()
        end
    end

    local function getVisibleListContentSize(): (number, number)
        local size = 0

        local contentStart = math.huge

        local listStart = list.AbsolutePosition.Y
        local listSize = list.AbsoluteSize.Y
        local listEnd = listStart + listSize

        for _, child in pairs(children) do
            local childStart = child.AbsolutePosition.Y
            local childSize = child.AbsoluteSize.Y
            local childEnd = childStart + childSize

            if childStart >= listStart and childEnd <= listEnd then
                size += childSize + childPadding

                -- Get content limits
                if childStart < contentStart then
                    contentStart = childStart
                end
            end
        end

        return size, contentStart
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------
    function carousel:SetNavigatorSize(newSize: number)
        local size = UDim2.new(1, 0, 0, newSize)
        nextNavigatorContainer.Size = size
        prevNavigatorContainer.Size = size

        list.Size = UDim2.fromScale(1, 1) - UDimUtil.scalarMultiplyUDim2(UDim2.fromOffset(0, newSize) + NAVIGATOR_PADDING, 2)
    end

    function carousel:SetNavigatorColor(newColor: Color3)
        navigatorColor = newColor
        nextNavigator:SetColor(navigatorColor, true)
        prevNavigator:SetColor(navigatorColor, true)
    end

    function carousel:SetChildPadding(newPadding: number)
        childPadding = newPadding
        listLayout.Padding = UDim.new(0, childPadding)
    end

    function carousel:SetTabSortOrder(newSortOrder: EnumItem)
        listLayout.SortOrder = newSortOrder
    end

    function carousel:MountChild(child: Instance)
        child.Parent = list
        table.insert(children, child)
    end

    function carousel:Mount(parent: GuiObject, hideParent: boolean?)
        if hideParent then
            parent.Transparency = 1
        end

        local zIndex = parent.ZIndex
        list.ZIndex = zIndex
        list.Parent = parent

        prevNavigatorContainer.Parent = parent
        prevNavigatorContainer.ZIndex = zIndex + 1
        prevNavigator:Mount(prevNavigatorContainer, true)

        nextNavigatorContainer.Parent = parent
        nextNavigatorContainer.ZIndex = zIndex + 1
        nextNavigator:Mount(nextNavigatorContainer, true)

        if IS_PLAYING then
            warn("NICE")

            if not UIScaleController then -- Just so that it works with hoarcekat
                UIScaleController = require(script.Parent.Parent.Scaling.UIScaleController)
            end

            -- Scrolling ( Asuumes all possible children have been added)
            list.CanvasSize = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y / UIScaleController.getScale())
            carousel:GetMaid():GiveTask(UIScaleController.ScaleChanged:Connect(function()
                updateNavigatorsEnabled()
            end))
        else
            list.CanvasSize = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y)
        end

        updateNavigatorsEnabled()
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------
    prevNavigatorContainer = createNavigatorContainer(UDim2.fromScale(0.5, 0), Vector2.new(0.5, 0))
    nextNavigator = createNavigator()

    nextNavigatorContainer = createNavigatorContainer(UDim2.fromScale(0.5, 1), Vector2.new(0.5, 1))
    prevNavigator = createNavigator()

    local defaults = Carousel.Defaults
    carousel:SetNavigatorSize(defaults.NavigatorSize)
    carousel:SetNavigatorColor(defaults.NavigatorColor)
    carousel:SetChildPadding(defaults.ChildPadding)
    carousel:SetTabSortOrder(defaults.TabSortOrder)

    prevNavigator.InternalRelease:Connect(function()
        if not scrollDb and isPrevNavigatorEnabled() then
            local canvasPosition = list.CanvasPosition
            local visibleContentSize, visibleContentStart = getVisibleListContentSize()
            local visibleContentEnd = visibleContentStart + visibleContentSize

            local positionDelta = visibleContentEnd - (list.AbsolutePosition.Y + list.AbsoluteSize.Y) - visibleContentSize
            positionDelta = math.max(positionDelta, -canvasPosition.Y)

            scrollDb = true
            local scroll =
                TweenService:Create(list, SCROLL_PREV_TWEEN_INFO, { CanvasPosition = list.CanvasPosition + Vector2.new(0, positionDelta) })
            scroll.Completed:Connect(function()
                updateNavigatorsEnabled()
                scrollDb = false
            end)
            scroll:Play()
        end
    end)

    nextNavigator.InternalRelease:Connect(function()
        if not scrollDb and isNextNavigatorEnabled() then
            local canvasPosition = list.CanvasPosition
            local visibleContentSize, visibleContentStart = getVisibleListContentSize()

            local positionDelta = (visibleContentStart - list.AbsolutePosition.Y) + visibleContentSize
            positionDelta = math.min(positionDelta, list.AbsoluteCanvasSize.Y - canvasPosition.Y)

            scrollDb = true
            local scroll =
                TweenService:Create(list, SCROLL_NEXT_TWEEN_INFO, { CanvasPosition = list.CanvasPosition + Vector2.new(0, positionDelta) })
            scroll.Completed:Connect(function()
                updateNavigatorsEnabled()
                scrollDb = false
            end)
            scroll:Play()
        end
    end)

    carousel:GetMaid():GiveTask(list:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if not scrollDb then
            updateNavigatorsEnabled()
        end
    end))

    return carousel
end

return Carousel
