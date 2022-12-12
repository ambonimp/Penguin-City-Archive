--[[
    Selection widget with different tabs with scrolling frames
]]
local SelectionPanel = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIElement = require(script.Parent.UIElement)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local Maid = require(ReplicatedStorage.Packages.maid)
local ExitButton = require(script.Parent.ExitButton)
local Button = require(script.Parent.Button)
local Signal = require(ReplicatedStorage.Shared.Signal)
local Queue = require(ReplicatedStorage.Shared.Queue)
local AnimatedButton = require(script.Parent.AnimatedButton)
local Products = require(ReplicatedStorage.Shared.Products.Products)
local ObjectPool = require(ReplicatedStorage.Shared.ObjectPool)

type Maid = typeof(Maid.new())
type Tab = {
    Name: string,
    ImageId: string,
    WidgetConstructors: {
        {
            WidgetName: string,
            Selected: boolean,
            Instance: Button.Button?,
            Constructor: (widget: Button.Button) -> (),
        }
    },
    Button: Button.Button?,
}

local ACTIVE_ARROW_BUTTON = "rbxassetid://11447909821"
local INACTIVE_ARROW_BUTTON = "rbxassetid://11807285632"

local COLUMN_WIDTH_OFFSET = 178

local TABS_PER_VIEW = {
    Left = 5,
    Right = 5,
    Bottom = 8,
}

local templateScreenGui: ScreenGui = game.StarterGui.SelectionPanel

SelectionPanel.Defaults = {
    Alignment = "Right",
    Columns = 1,
    Rows = 1,
}

function SelectionPanel.new()
    local selectionPanel = UIElement.new()

    local alignment: "Left" | "Right" | "Bottom" = SelectionPanel.Defaults.Alignment
    local rows = SelectionPanel.Defaults.Rows
    local columns = SelectionPanel.Defaults.Columns
    local size = rows * columns

    local tabs: { Tab } = {}
    local openTabName: string | nil
    local openTabNameByTabIndex: { [number]: string | nil } = {} -- Memory for when we rotate between tabs

    local containerMaid = Maid.new()
    local drawMaid = Maid.new()
    selectionPanel:GetMaid():GiveTask(containerMaid)
    selectionPanel:GetMaid():GiveTask(drawMaid)

    local parent: GuiBase | GuiObject | nil
    local containerFrame: Frame
    local backgroundFrame: Frame
    local tabsFrame: Frame
    local scrollingFrame: Frame
    local closeButton: typeof(ExitButton.new())
    local closeButtonFrame: Frame
    local backwardArrow: AnimatedButton.AnimatedButton
    local forwardArrow: AnimatedButton.AnimatedButton

    local defaultBackgroundPosition: UDim2
    local defaultScrollingFrameSize: UDim2

    local widgetPool = ObjectPool.new(size, function()
        return { Widget = Button.new(Instance.new("ImageButton")) } :: ObjectPool.ObjectGroup
    end, function(group)
        local widget: Button.Button = group.Widget

        widget.Pressed:DisconnectAll()
        widget.InternalEnter:DisconnectAll()
        widget.InternalPress:DisconnectAll()
        widget.InternalLeave:DisconnectAll()
        widget.InternalRelease:DisconnectAll()
        widget.InternalEnter:DisconnectAll()
        --TODO: Selection Changed

        widget:Mount()
    end)

    local tabsIndex = 1
    local pageIndex = 1

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------
    selectionPanel.TabChanged = Signal.new()
    selectionPanel.ClosePressed = Signal.new()
    selectionPanel:GetMaid():GiveTask(selectionPanel.ClosePressed)

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------
    local function getTabsPerView()
        return TABS_PER_VIEW[alignment]
    end

    local function getMaxTabsIndex()
        return math.clamp(math.ceil(#tabs / getTabsPerView()), 1, math.huge)
    end

    local function updateTabIndex(increaseBy: number)
        tabsIndex = math.clamp(tabsIndex + increaseBy, 1, getMaxTabsIndex())

        -- Select last tab
        local lastOpenTabName = openTabNameByTabIndex[tabsIndex]
        if lastOpenTabName then
            selectionPanel:OpenTab(lastOpenTabName)
            return
        end

        -- Select new tab
        local tabIndex = ((tabsIndex - 1) * getTabsPerView()) + 1
        selectionPanel:OpenTab(tabs[tabIndex].Name)
    end

    local function getTab(tabName: string)
        for _, tab in pairs(tabs) do
            if tab.Name == tabName then
                return tab
            end
        end
        return nil
    end

    local function getWidgetConstructor(tab: Tab, widgetName: string)
        for _, widgetInfo in pairs(tab.WidgetConstructors) do
            if widgetInfo.WidgetName == widgetName then
                return widgetInfo.Constructor
            end
        end
        return nil
    end

    local function getVisibleTabs()
        local visibleTabs: { Tab } = {}

        local startIndex = (tabsIndex - 1) * getTabsPerView() + 1
        for i = startIndex, startIndex + (getTabsPerView() - 1) do
            table.insert(visibleTabs, tabs[i])
        end

        return visibleTabs
    end

    local function resize()
        if alignment == "Left" then
            backgroundFrame.Position = defaultBackgroundPosition + UDim2.fromOffset((columns - 1) * COLUMN_WIDTH_OFFSET, 0)
            scrollingFrame.Size = defaultScrollingFrameSize + UDim2.fromOffset((columns - 1) * COLUMN_WIDTH_OFFSET, 0)
        elseif alignment == "Right" then
            backgroundFrame.Position = defaultBackgroundPosition - UDim2.fromOffset((columns - 1) * COLUMN_WIDTH_OFFSET, 0)
            scrollingFrame.Size = defaultScrollingFrameSize + UDim2.fromOffset((columns - 1) * COLUMN_WIDTH_OFFSET, 0)
        elseif alignment == "Bottom" then
            backgroundFrame.Position = defaultBackgroundPosition - UDim2.fromOffset(0, (columns - 1) * COLUMN_WIDTH_OFFSET)
            scrollingFrame.Size = defaultScrollingFrameSize + UDim2.fromOffset(0, (columns - 1) * COLUMN_WIDTH_OFFSET)
        else
            error(("Missing edgecase for %q"):format(alignment))
        end
    end

    local function createContainer()
        containerMaid:Cleanup()

        -- Get "Background"
        containerFrame = templateScreenGui:FindFirstChild(alignment)
        if not containerFrame then
            error(("Missing GuiObject for alignment %q"):format(alignment))
        end
        containerFrame = containerFrame:Clone()
        backgroundFrame = containerFrame.Background
        closeButtonFrame = backgroundFrame.Side.CloseButton
        containerMaid:GiveTask(containerFrame)

        if parent then
            selectionPanel:Mount(parent)
        end

        -- Close
        closeButton = ExitButton.new()
        closeButton:Mount(backgroundFrame.Side.CloseButton, true)
        closeButton.Pressed:Connect(function()
            selectionPanel.ClosePressed:Fire()
        end)
        containerMaid:GiveTask(closeButton)

        -- Arrows
        tabsIndex = 1

        backwardArrow = AnimatedButton.new(backgroundFrame.Side.BackwardArrow.ImageButton)
        backwardArrow.Pressed:Connect(function()
            updateTabIndex(-1)
        end)
        containerMaid:GiveTask(backwardArrow)

        forwardArrow = AnimatedButton.new(backgroundFrame.Side.ForwardArrow.ImageButton)
        forwardArrow.Pressed:Connect(function()
            updateTabIndex(1)
        end)
        containerMaid:GiveTask(forwardArrow)

        -- Tabs
        tabsFrame = backgroundFrame.Side.Tabs
        tabsFrame.Selected.Visible = false
        tabsFrame.template.Visible = false

        -- Widgets
        scrollingFrame = backgroundFrame.Back.ScrollingFrame
        scrollingFrame.sectionTemplate.Visible = false
        scrollingFrame.sectionTemplate.template.Visible = false

        -- Misc
        defaultBackgroundPosition = backgroundFrame.Position
        defaultScrollingFrameSize = scrollingFrame.Size

        -- Logic
        resize()
    end

    local function drawPage(tab: Tab)
        widgetPool:ReleaseAll()

        local widgetConstructors = tab.WidgetConstructors

        local indexStart = (pageIndex - 1) * size + 1
        local indexEnd = math.min(size, #widgetConstructors - indexStart)
        for i = indexStart, indexEnd do
            local widget = widgetPool:GetObject()
            widgetPool:Mount(scrollingFrame)

            local widgetInfo = widgetConstructors[i]
            widgetInfo.Instance = widget
            widgetInfo.Constructor(widget)
        end

        widgetPool.Cleared:Once(function()
            for i = indexStart, indexEnd do
                widgetConstructors[i].Instance = nil
            end
        end)
    end

    local function draw(updatedAlignment: boolean?)
        if updatedAlignment then
            createContainer()
        end
        drawMaid:Cleanup()

        -- Tabs
        local openTab: Tab
        do
            local visibleTabs = getVisibleTabs()
            if #visibleTabs == 0 or not openTabName then
                tabsFrame.Selected.Visible = false
            end

            -- Create and/or update visible tab buttons
            local newTabButtons = {}
            for index, visibleTab in pairs(visibleTabs) do
                -- Create
                local button = visibleTab.Button
                if not button then
                    local textButton: TextButton = tabsFrame.template:Clone()
                    textButton.Name = visibleTab.Name
                    textButton.Visible = true
                    textButton.Icon.Image = visibleTab.ImageId
                    textButton.Parent = tabsFrame

                    button = Button.new(textButton)
                    button.Pressed:Connect(function()
                        selectionPanel:OpenTab(visibleTab.Name)
                    end)
                    visibleTab.Button = button
                end
                table.insert(newTabButtons, button)

                -- Update
                button:GetButtonObject().LayoutOrder = index
                button:GetButtonObject().Visible = not (openTabName == visibleTab.Name)

                -- Selected
                if openTabName == visibleTab.Name then
                    openTab = visibleTab

                    tabsFrame.Selected.Visible = true
                    tabsFrame.Selected.LayoutOrder = index
                    tabsFrame.Selected.Icon.Image = visibleTab.ImageId
                end
            end

            -- Cull old tab buttons + update caches
            for _, tab in pairs(tabs) do
                if tab.Button and not table.find(newTabButtons, tab.Button) then
                    tab.Button:Destroy()
                    tab.Button = nil
                end
            end
        end

        -- Arrows
        do
            backwardArrow:GetButtonObject().Image = if tabsIndex == 1 then ACTIVE_ARROW_BUTTON else INACTIVE_ARROW_BUTTON
            forwardArrow:GetButtonObject().Image = if tabsIndex == getMaxTabsIndex() then ACTIVE_ARROW_BUTTON else INACTIVE_ARROW_BUTTON
        end

        -- Widgets
        if openTab then
            pageIndex = 1

            drawPage(openTab)

            --TODO: If #openTab.WidgetConstructors > size then show navigation buttons which will invoke drawPage
        end
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------
    function selectionPanel:Mount(newParent: GuiBase | GuiObject, hideParent: boolean?)
        parent = newParent
        containerFrame.Parent = parent

        if hideParent and parent:IsA("GuiObject") then
            parent.BackgroundTransparency = 1
        end

        -- WARN: Unintended Behaviour
        local screenGui = newParent:IsA("ScreenGui") and newParent or newParent:FindFirstAncestorOfClass("ScreenGui")
        if screenGui then
            if screenGui.ZIndexBehavior ~= Enum.ZIndexBehavior.Global then
                warn(
                    ("ScreenGui %q must have ZIndexBehavior Enum.ZIndexBehavior.Global for SelectionPanel to function properly"):format(
                        screenGui:GetFullName()
                    )
                )
            end
        end
    end

    function selectionPanel:SetSize(newRows: number, newColumns: number)
        rows = newRows
        columns = newColumns

        resize()
        draw()
    end

    function selectionPanel:GetContainer()
        return containerFrame
    end

    function selectionPanel:SetAlignment(newAlignmnet: "Left" | "Right" | "Bottom")
        -- RETURN: Not changed
        if newAlignmnet == alignment then
            return
        end

        alignment = newAlignmnet
        draw(true)
    end

    function selectionPanel:SetCloseButtonVisibility(isVisible: boolean)
        closeButtonFrame.Visible = isVisible
    end

    -------------------------------------------------------------------------------
    -- Tabs
    -------------------------------------------------------------------------------
    function selectionPanel:AddTab(tabName: string, imageId: string)
        -- WARN: Already exists
        if getTab(tabName) then
            warn(("%q already exists!"):format(tabName))
            return
        end

        local tab: Tab = {
            Name = tabName,
            ImageId = imageId,
            WidgetConstructors = {},
        }
        table.insert(tabs, tab)

        -- EDGE CASE: Select only tab
        if #tabs == 1 then
            selectionPanel:OpenTab(tabName)
            return
        end

        draw()
    end

    function selectionPanel:RemoveTab(tabName: string)
        for index, tab in pairs(tabs) do
            if tab.Name == tabName then
                table.remove(tabs, index)
            end
        end

        -- Open a different tab if this was opened
        if openTabName == tabName then
            for _, someTab in pairs(tabs) do
                selectionPanel:OpenTab(someTab.Name)
                return
            end
        end
        selectionPanel:OpenTab()
    end

    -------------------------------------------------------------------------------
    -- Widget types
    -------------------------------------------------------------------------------

    function selectionPanel:AddWidgetConstructor(
        tabName: string,
        widgetName: string,
        selected: boolean,
        constructor: (widget: Button.Button) -> ()
    )
        -- WARN: Bad tab
        local tab = getTab(tabName)
        if not tab then
            warn(("No tab %q exits"):format(tabName))
            return
        end

        -- WARN: Already exists
        if getWidgetConstructor(tab, widgetName) then
            warn(("Widget %s.%s already exists!"):format(tabName, widgetName))
            return
        end

        table.insert(tab.WidgetConstructors, {
            WidgetName = widgetName,
            Selected = selected,
            Constructor = constructor,
        })

        if openTabName == tab.Name then
            draw()
        end
    end

    function selectionPanel:SetWidgetSelected(tabName: string, widgetName, toggle: boolean)
        -- WARN: Bad tab
        local tab = getTab(tabName)
        if not tab then
            warn(("No tab %q exits"):format(tabName))
            return
        end

        for _, widgetInfo in pairs(tab.WidgetConstructors) do
            if widgetInfo.WidgetName == widgetName then
                widgetInfo.Selected = toggle
                local widget = widgetInfo.Instance
                if widget then
                    print("Selected")
                    -- TODO: widget:SetSelected(toggle)
                end
                break
            end
        end
    end

    function selectionPanel:RemoveWidget(tabName: string, widgetName: string)
        -- WARN: Bad tab
        local tab = getTab(tabName)
        if not tab then
            warn(("No tab %q exits"):format(tabName))
            return
        end

        for index, widgetInfo in pairs(tab.WidgetConstructors) do
            if widgetInfo.WidgetName == widgetName then
                table.remove(tab.WidgetConstructors, index)
                break
            end
        end

        -- Draw if this would be visible right now
        if openTabName == tabName then
            draw()
        end
    end

    return selectionPanel
end

return SelectionPanel
