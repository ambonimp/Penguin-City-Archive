--[[
    Selection widget with different tabs with scrolling frames
]]
local SelectionPanel = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(ReplicatedStorage.Packages.maid)
local UIElement = require(Paths.Client.UI.Elements.UIElement)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local Button = require(Paths.Client.UI.Elements.Button)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local Signal = require(Paths.Shared.Signal)
local Queue = require(Paths.Shared.Queue)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local Products = require(Paths.Shared.Products.Products)
local ObjectPool = require(Paths.Shared.ObjectPool)
local Images = require(Paths.Shared.Images.Images)
local Widget = require(Paths.Client.UI.Elements.Widget)

type Maid = typeof(Maid.new())
type Tab = {
    Name: string,
    ImageId: string,
    WidgetConstructors: {
        {
            WidgetName: string,
            Selected: boolean,
            Instance: KeyboardButton.KeyboardButton?,
            Constructor: (widget: KeyboardButton.KeyboardButton) -> (),
        }
    },
    Button: (Button.Button)?,
}

local COLUMN_WIDTH_OFFSET = 178
local CELL_SIZE = 166
local PAGINATION_PADDING = 10

local TABS_PER_VIEW = {
    Left = 5,
    Right = 5,
    Bottom = 8,
}

local templateScreenGui: ScreenGui = game.StarterGui.SelectionPanelTest

SelectionPanel.Defaults = {
    Alignment = "Right",
    Columns = 1,
    Rows = 10,
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
    local paginationFrame: Frame
    local scrollingFrame: Frame
    local closeButton: typeof(ExitButton.new())
    local closeButtonFrame: Frame
    local backwardArrow: AnimatedButton.AnimatedButton
    local forwardArrow: AnimatedButton.AnimatedButton

    local nextPageButton: KeyboardButton.KeyboardButton
    local prevPageButton: KeyboardButton.KeyboardButton

    local defaultBackgroundPosition: UDim2
    local defaultScrollingFrameSize: UDim2

    local scrollingFrameSize: UDim2

    local widgetPool = ObjectPool.new(size, function()
        local button = KeyboardButton.new()
        button:GetButtonObject().Size = UDim2.fromOffset(CELL_SIZE, CELL_SIZE)

        return { Widget = button } :: ObjectPool.ObjectGroup
    end, function(group)
        local widget: KeyboardButton.KeyboardButton = group.Widget

        widget.Pressed:DisconnectAll()
        widget.InternalEnter:DisconnectAll()
        widget.InternalPress:DisconnectAll()
        widget.InternalLeave:DisconnectAll()
        widget.InternalRelease:DisconnectAll()
        widget.InternalEnter:DisconnectAll()
        --TODO: Selection Changed

        widget:Mount()
    end)
    selectionPanel:GetMaid():GiveTask(widgetPool)

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
            scrollingFrameSize = defaultScrollingFrameSize + UDim2.fromOffset((columns - 1) * COLUMN_WIDTH_OFFSET, 0)
            paginationFrame.Size = UDim2.fromOffset(scrollingFrameSize.X.Offset, paginationFrame.Size.Y.Offset)
        elseif alignment == "Right" then
            backgroundFrame.Position = defaultBackgroundPosition - UDim2.fromOffset((columns - 1) * COLUMN_WIDTH_OFFSET, 0)
            scrollingFrameSize = defaultScrollingFrameSize + UDim2.fromOffset((columns - 1) * COLUMN_WIDTH_OFFSET, 0)
            paginationFrame.Size = UDim2.fromOffset(scrollingFrameSize.X.Offset, paginationFrame.Size.Y.Offset)
        elseif alignment == "Bottom" then
            backgroundFrame.Position = defaultBackgroundPosition - UDim2.fromOffset(0, (columns - 1) * COLUMN_WIDTH_OFFSET)
            scrollingFrameSize = defaultScrollingFrameSize + UDim2.fromOffset(0, (columns - 1) * COLUMN_WIDTH_OFFSET)
        else
            error(("Missing edgecase for %q"):format(alignment))
        end

        scrollingFrame.Size = scrollingFrameSize
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

        -- Pages
        paginationFrame = backgroundFrame.Back.Pagination
        nextPageButton = KeyboardButton.new()
        nextPageButton:SetIcon(Images.StampBook.NavigationArrowRight)
        nextPageButton:Mount(paginationFrame.Next, true)

        prevPageButton = KeyboardButton.new()
        prevPageButton:SetIcon(Images.StampBook.NavigationArrowLeft)
        prevPageButton:Mount(paginationFrame.Previous, true)

        -- Widgets
        scrollingFrame = backgroundFrame.Back.ScrollingFrame

        -- Misc
        defaultBackgroundPosition = backgroundFrame.Position
        defaultScrollingFrameSize = scrollingFrame.Size

        -- Logic
        resize()
    end

    local function drawPage()
        local widgetConstructors = getTab(openTabName).WidgetConstructors
        local widgetCount = #widgetConstructors

        -- RETURN: Nothing to draw
        if widgetCount == 0 then
            return
        end

        local indexStart = (pageIndex - 1) * size + 1
        local indexEnd = indexStart + math.min(size - 1, widgetCount - 1, math.max(0, widgetCount - indexStart))

        widgetPool:Clear()
        widgetPool.Cleared:Once(function()
            for i = indexStart, indexEnd do
                widgetConstructors[i].Instance = nil
            end
        end)

        for i = indexStart, indexEnd do
            local widgetGroup = widgetPool:Get()
            local widget: KeyboardButton.KeyboardButton = widgetGroup.Widget
            widget:Mount(scrollingFrame)

            local widgetInfo = widgetConstructors[i]
            widgetInfo.Instance = widget
            widgetInfo.Constructor(widget)
        end
    end

    local function draw(updatedAlignment: boolean?)
        local queueNext = Queue.yield(selectionPanel)

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
            backwardArrow:GetButtonObject().Image = if tabsIndex == 1
                then Images.SelectionPanel.BlueArrow
                else Images.SelectionPanel.GrayArrow
            forwardArrow:GetButtonObject().Image = if tabsIndex == getMaxTabsIndex()
                then Images.SelectionPanel.BlueArrow
                else Images.SelectionPanel.GrayArrow
        end

        -- Widgets
        if openTab then
            pageIndex = 1
            drawPage()

            local widgetCount = #openTab.WidgetConstructors
            local pageCount = math.ceil(widgetCount / size)

            if widgetCount > size then
                paginationFrame.Visible = true
                scrollingFrame.Size = scrollingFrameSize
                    - (
                        if alignment == "Bottom"
                            then UDim2.fromOffset((paginationFrame.Previous.Size.X.Offset + PAGINATION_PADDING) * 2, 0)
                            else UDim2.fromOffset(0, paginationFrame.Size.Y.Offset + PAGINATION_PADDING)
                    )

                local function updatePaginationText()
                    if alignment ~= "Bottom" then
                        paginationFrame.Text.Text = pageIndex .. "/" .. pageCount
                    end
                end

                updatePaginationText()

                drawMaid:GiveTask(nextPageButton.Pressed:Connect(function()
                    pageIndex = if pageIndex == pageCount then 1 else pageIndex + 1
                    updatePaginationText()
                    drawPage()
                end))

                drawMaid:GiveTask(prevPageButton.Pressed:Connect(function()
                    pageIndex = if pageIndex == 1 then pageCount else pageIndex - 1
                    updatePaginationText()
                    drawPage()
                end))
            else
                paginationFrame.Visible = false
                scrollingFrame.Size = scrollingFrameSize
            end
        end

        queueNext()
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
        size = rows * columns

        widgetPool:Resize(size)
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

    function selectionPanel:OpenTab(tabName: string?)
        -- WARN: Bad tab
        local tab = getTab(tabName)
        if tabName and not tab then
            warn(("No tab %q exits"):format(tabName))
            return
        end

        if openTabName then
            for _, widgetInfo in pairs(getTab(openTabName).WidgetConstructors) do
                widgetInfo.Instance = nil
            end
        end
        selectionPanel.TabChanged:Fire(openTabName, tabName)

        openTabName = tabName
        openTabNameByTabIndex[tabsIndex] = tabName or openTabNameByTabIndex[tabsIndex]

        draw()
    end

    -------------------------------------------------------------------------------
    -- Widget types
    -------------------------------------------------------------------------------

    function selectionPanel:AddWidgetConstructor(
        tabName: string,
        widgetName: string,
        selected: boolean,
        constructor: (widget: KeyboardButton.KeyboardButton) -> ()
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

    -------------------------------------------------------------------------------
    -- Setup
    -------------------------------------------------------------------------------
    draw(true)
    selectionPanel:SetSize(rows, columns)

    return selectionPanel
end

return SelectionPanel
