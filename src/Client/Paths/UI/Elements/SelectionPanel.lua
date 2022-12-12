--[[
    Selection widget with different tabs with scrolling frames
]]
local SelectionPanel = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIElement = require(Paths.Client.UI.Elements.UIElement)
local MathUtil = require(Paths.Shared.Utils.MathUtil)
local Maid = require(Paths.Packages.maid)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local Button = require(Paths.Client.UI.Elements.Button)
local Signal = require(Paths.Shared.Signal)
local Queue = require(Paths.Shared.Queue)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local Products = require(Paths.Shared.Products.Products)
local Widget = require(Paths.Client.UI.Elements.Widget)

type Tab = {
    Name: string,
    ImageId: string,
    WidgetConstructors: { {
        WidgetName: string,
        Selected: boolean,
        Instance: Widget.Widget?,
        Constructor: (parent: GuiObject, maid: typeof(Maid.new())) -> Widget.Widget,
    } },
    Button: Button.Button | nil,
}

local TABS_PER_VIEW = {
    Left = 5,
    Right = 5,
    Bottom = 8,
}
local SECTION_WIDTH_OFFSET = 178

SelectionPanel.Defaults = {
    Alignment = "Right",
    Size = 1,
}

local selectionPanelScreenGui: ScreenGui = game.StarterGui.SelectionPanel

function SelectionPanel.new()
    local selectionPanel = UIElement.new()

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local alignment: "Left" | "Right" | "Bottom" = SelectionPanel.Defaults.Alignment
    local size = SelectionPanel.Defaults.Size

    local tabs: { Tab } = {}
    local openTabName: string | nil
    local openTabNameByTabIndex: { [number]: string | nil } = {} -- Memory for when we rotate between tabs
    local sections: { Frame } = {}

    local containerMaid = Maid.new()
    local drawMaid = Maid.new()
    selectionPanel:GetMaid():GiveTask(containerMaid)
    selectionPanel:GetMaid():GiveTask(drawMaid)

    local parent: GuiBase | GuiObject | nil
    local containerFrame: Frame
    local backgroundFrame: Frame
    local closeButtonFrame: Frame
    local tabsFrame: Frame
    local scrollingFrame: Frame
    local closeButton: typeof(ExitButton.new())
    local backwardArrow: AnimatedButton.AnimatedButton
    local forwardArrow: AnimatedButton.AnimatedButton

    local defaultBackgroundPosition: UDim2
    local defaultScrollingFrameSize: UDim2

    local arrowVisible: boolean = true
    local hiddenTabs: { string } = {}
    local tabsIndex = 1

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    selectionPanel.TabChanged = Signal.new()
    selectionPanel.ClosePressed = Signal.new()
    selectionPanel.TabChanged = Signal.new()
    selectionPanel:GetMaid():GiveTask(selectionPanel.ClosePressed)

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    -- Hoist
    local function draw() end

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

    local function getSection(widgetIndex: number)
        return sections[MathUtil.wrapAround(widgetIndex, size)]
    end

    local function resize()
        if alignment == "Left" then
            backgroundFrame.Position = defaultBackgroundPosition + UDim2.fromOffset((size - 1) * SECTION_WIDTH_OFFSET, 0)
            scrollingFrame.Size = defaultScrollingFrameSize + UDim2.fromOffset((size - 1) * SECTION_WIDTH_OFFSET, 0)
        elseif alignment == "Right" then
            backgroundFrame.Position = defaultBackgroundPosition - UDim2.fromOffset((size - 1) * SECTION_WIDTH_OFFSET, 0)
            scrollingFrame.Size = defaultScrollingFrameSize + UDim2.fromOffset((size - 1) * SECTION_WIDTH_OFFSET, 0)
        elseif alignment == "Bottom" then
            backgroundFrame.Position = defaultBackgroundPosition - UDim2.fromOffset(0, (size - 1) * SECTION_WIDTH_OFFSET)
            scrollingFrame.Size = defaultScrollingFrameSize + UDim2.fromOffset(0, (size - 1) * SECTION_WIDTH_OFFSET)
        else
            error(("Missing edgecase for %q"):format(alignment))
        end
    end

    local function createContainer()
        containerMaid:Cleanup()

        -- Get "Background"
        containerFrame = selectionPanelScreenGui:FindFirstChild(alignment)
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

    function draw(updatedAlignment: boolean?)
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

                if table.find(hiddenTabs, visibleTab.Name) then
                    button:GetButtonObject().Visible = false
                end
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
            backwardArrow:GetButtonObject().Visible = not (tabsIndex == 1)
            forwardArrow:GetButtonObject().Visible = not (tabsIndex == getMaxTabsIndex())

            if arrowVisible == false then
                forwardArrow:GetButtonObject().Visible = false
            end
        end

        -- Widgets
        if openTab then
            for i, widgetInfo in pairs(openTab.WidgetConstructors) do
                local section = getSection(i)

                local widgetFrame: Frame = section.template:Clone()
                widgetFrame.Name = widgetInfo.WidgetName
                widgetFrame.LayoutOrder = i
                widgetFrame.Visible = true
                widgetFrame.Parent = section
                drawMaid:GiveTask(widgetFrame)

                widgetFrame.Background:Destroy()

                local widget = widgetInfo.Constructor(widgetFrame, drawMaid)
                widget:SetSelected(widgetInfo.Selected)
                widgetInfo.Instance = widget
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

    function selectionPanel:GetContainer()
        return containerFrame
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

    function selectionPanel:HideForwardArrow()
        if tabsIndex > 1 then
            updateTabIndex(-1)
        end
        arrowVisible = false
    end

    function selectionPanel:ShowForwardArrow()
        arrowVisible = true
    end

    function selectionPanel:GetOpenTabName()
        return openTabName
    end

    function selectionPanel:SetAlignment(newAlignmnet: "Left" | "Right" | "Bottom")
        -- RETURN: Not changed
        if newAlignmnet == alignment then
            return
        end

        alignment = newAlignmnet
        draw(true)
    end

    -- Sets the row/column count (depends on alignment)
    function selectionPanel:SetSize(newSize: number)
        size = newSize

        -- Clear old Sections
        for _, oldSection in pairs(sections) do
            oldSection:Destroy()
        end
        sections = {}

        -- Create New
        for i = 1, newSize do
            local section: Frame = scrollingFrame.sectionTemplate:Clone()
            section.Name = ("Section %d"):format(i)
            section.LayoutOrder = i
            section.Visible = true
            section.Parent = scrollingFrame
            table.insert(sections, section)
        end

        resize()
        draw()
    end

    function selectionPanel:HideTab(tabName: string)
        if table.find(hiddenTabs, tabName) then --already hidden
            return
        end
        table.insert(hiddenTabs, tabName)

        draw()
    end

    function selectionPanel:ShowTab(tabName: string)
        if table.find(hiddenTabs, tabName) then --is hidden
            table.remove(hiddenTabs, table.find(hiddenTabs, tabName))

            draw()
        end
    end

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

    function selectionPanel:AddWidgetConstructor(
        tabName: string,
        widgetName: string,
        selected: boolean,
        constructor: ((parent: GuiObject, maid: typeof(Maid.new())) -> Widget.Widget)
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
            Constructor = constructor,
            Selected = selected,
        })

        if openTabName == tab.Name then
            draw()
        end
    end

    function selectionPanel:AddWidgetFromProduct(
        tabName: string,
        widgetName: string,
        selected: boolean,
        product: Products.Product,
        state: {
            VerifyOwnership: boolean?,
            ShowTotals: boolean?,
            HideText: boolean?,
        }?,
        onClicked: (() -> ())?,
        onCreated: ((Widget.Widget) -> ())?
    )
        selectionPanel:AddWidgetConstructor(tabName, widgetName, selected, function(widgetParent, maid)
            local widget = Widget.diverseWidgetFromProduct(product, state, function(button)
                button.Pressed:Connect(function()
                    if onClicked then
                        onClicked()
                    end
                end)
            end)

            if not state or not state.VerifyOwnership then
                widget.Pressed:Connect(function()
                    if onClicked then
                        onClicked()
                    end
                end)
            end

            if onCreated then
                onCreated(widget)
            end

            widget:Mount(widgetParent)
            maid:GiveTask(widget)

            return widget
        end)
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
                    widget:SetSelected(toggle)
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

    function selectionPanel:RemoveWidgets(tabName: string)
        -- WARN: Bad tab
        local tab = getTab(tabName)
        if not tab then
            warn(("No tab %q exits"):format(tabName))
            return
        end

        tab.WidgetConstructors = {}

        -- Draw if this would be visible right now
        if openTabName == tabName then
            draw()
        end
    end

    function selectionPanel:SetCloseButtonVisibility(isVisible: boolean)
        closeButtonFrame.Visible = isVisible
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    -- Setup
    draw(true)
    selectionPanel:SetSize(size)

    return selectionPanel
end

return SelectionPanel
