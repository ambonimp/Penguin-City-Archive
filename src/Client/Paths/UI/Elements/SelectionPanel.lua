--[[
    Selection widget with different tabs with scrolling frames
]]
local SelectionPanel = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIElement = require(script.Parent.UIElement)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local Maid = require(ReplicatedStorage.Packages.maid)
local ExitButton = require(script.Parent.ExitButton)
local AnimatedButton = require(script.Parent.AnimatedButton)
local Signal = require(ReplicatedStorage.Shared.Signal)
local Queue = require(ReplicatedStorage.Shared.Queue)

type Widget = {
    Name: string,
    ImageId: string,
}

type Tab = {
    Name: string,
    ImageId: string,
    Widgets: { Widget },
    Button: AnimatedButton.AnimatedButton | nil,
}

local TABS_PER_VIEW = 6

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
    local tabButtons: { AnimatedButton.AnimatedButton } = {}
    local openTabName: string | nil

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
    local backwardArrow: AnimatedButton.AnimatedButton
    local forwardArrow: AnimatedButton.AnimatedButton

    local tabsIndex = 1

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    selectionPanel.ClosePressed = Signal.new()

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function getMaxTabsIndex()
        return math.ceil(#tabs / TABS_PER_VIEW)
    end

    local function updateTabIndex(increaseBy: number)
        tabsIndex = math.clamp(tabsIndex + increaseBy, 1, getMaxTabsIndex())
    end

    local function getTab(tabName: string)
        for _, tab in pairs(tabs) do
            if tab.Name == tabName then
                return tab
            end
        end
        return nil
    end

    local function getWidget(tab: Tab, widgetName: string)
        for _, widget in pairs(tab.Widgets) do
            if widget.Name == widgetName then
                return widget
            end
        end
        return nil
    end

    local function getVisibleTabs()
        local visibleTabs: { Tab } = {}

        local startIndex = (tabsIndex - 1) * TABS_PER_VIEW + 1
        for i = startIndex, startIndex + (TABS_PER_VIEW - 1) do
            table.insert(visibleTabs, tabs[i])
        end

        return visibleTabs
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

        scrollingFrame.Section.template.Visible = false
    end

    local function draw(updatedAlignment: boolean?)
        local queueNext = Queue.yield(selectionPanel)

        if updatedAlignment then
            createContainer()
        end
        drawMaid:Cleanup()

        -- Tabs
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

                    button = AnimatedButton.new(textButton)
                    button.Pressed:Connect(function()
                        selectionPanel:OpenTab(visibleTab.Name)
                    end)
                    visibleTab.Button = button
                end
                table.insert(tabButtons, button)

                -- Update
                button:GetButtonObject().LayoutOrder = index
                button:GetButtonObject().Visible = not openTabName == visibleTab.Name

                -- Selected
                if openTabName == visibleTab.Name then
                    tabsFrame.Selected.Visible = true
                    tabsFrame.Selected.LayoutOrder = index
                    tabsFrame.Selected.Icon.Image = visibleTab.ImageId
                end
            end

            -- Cull old tab buttons + update cache to new ones
            for _, tabButton in pairs(tabButtons) do
                if not table.find(newTabButtons, tabButton) then
                    tabButton:Destroy()
                end
            end
            tabButtons = newTabButtons
        end

        -- Arrows
        do
            backwardArrow:GetButtonObject().Visible = not tabsIndex == 1
            forwardArrow:GetButtonObject().Visible = not tabsIndex == getMaxTabsIndex()
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
    end

    function selectionPanel:OpenTab(tabName: string?)
        openTabName = tabName
        draw()
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
        draw()
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
            Widgets = {},
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

    function selectionPanel:AddWidget(tabName: string, widgetName: string, imageId: string)
        -- WARN: Bad tab
        local tab = getTab(tabName)
        if not tab then
            warn(("No tab %q exits"):format(tabName))
            return
        end

        -- WARN: Already exists
        if getWidget(tab, widgetName) then
            warn(("Widget %s.%s already exists!"):format(tabName, widgetName))
            return
        end

        local widget: Widget = {
            Name = widgetName,
            ImageId = imageId,
        }
        table.insert(tab.Widgets, widget)

        -- Draw if this would be visible right now
        if openTabName == tab.Name then
            draw()
        end
    end

    function selectionPanel:RemoveWidget(tabName: string, widgetName: string)
        -- WARN: Bad tab
        local tab = getTab(tabName)
        if not tab then
            warn(("No tab %q exits"):format(tabName))
            return
        end

        for index, widget in pairs(tab.Widgets) do
            if widget.Name == widgetName then
                table.remove(tab.Widgets, index)
            end
        end

        -- Draw if this would be visible right now
        if openTabName == tabName then
            draw()
        end
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    draw(true)

    return selectionPanel
end

return SelectionPanel
