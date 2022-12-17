--[[
    A window that we can add tabs to, then mount custom pages inside it.

    Derived from SelectionPanel - copy+pasted as they functionally different enough that a super class would take a significant time to design
]]
local TabbedWindow = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIElement = require(Paths.Client.UI.Elements.UIElement)
local Maid = require(Paths.Shared.Maid)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local Button = require(Paths.Client.UI.Elements.Button)
local Signal = require(Paths.Shared.Signal)
local Queue = require(Paths.Shared.Queue)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)

type Tab = {
    Name: string,
    ImageId: string,
    Button: Button.Button | nil,
    WindowFrame: Frame?,
    WindowConstructor: ((parent: GuiObject, maid: typeof(Maid.new())) -> nil)?,
}

local TABS_PER_VIEW = 5

local tabbedWindowScreenGui: ScreenGui = game.StarterGui.TabbedWindow

--[[
    - `closeCallbackState`: See `ExitButton`
]]
function TabbedWindow.new(closeCallbackState: string?)
    local tabbedWindow = UIElement.new()

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local tabs: { Tab } = {}
    local openTabName: string | nil
    local openTabNameByTabIndex: { [number]: string | nil } = {} -- Memory for when we rotate between tabs

    local containerMaid = Maid.new()
    local drawMaid = Maid.new()
    tabbedWindow:GetMaid():GiveTask(containerMaid)
    tabbedWindow:GetMaid():GiveTask(drawMaid)

    local parent: GuiBase | GuiObject | nil
    local containerFrame: Frame
    local backgroundFrame: Frame
    local tabsFrame: Frame
    local closeButton: typeof(ExitButton.new())
    local backwardArrow: AnimatedButton.AnimatedButton
    local forwardArrow: AnimatedButton.AnimatedButton

    local tabsIndex = 1

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    tabbedWindow.ClosePressed = Signal.new()
    tabbedWindow:GetMaid():GiveTask(tabbedWindow.ClosePressed)

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    -- Hoist
    local function draw() end

    local function getMaxTabsIndex()
        return math.clamp(math.ceil(#tabs / TABS_PER_VIEW), 1, math.huge)
    end

    local function updateTabIndex(increaseBy: number)
        tabsIndex = math.clamp(tabsIndex + increaseBy, 1, getMaxTabsIndex())

        -- Select last tab
        local lastOpenTabName = openTabNameByTabIndex[tabsIndex]
        if lastOpenTabName then
            tabbedWindow:OpenTab(lastOpenTabName)
            return
        end

        -- Select new tab
        local tabIndex = ((tabsIndex - 1) * TABS_PER_VIEW) + 1
        tabbedWindow:OpenTab(tabs[tabIndex].Name)
    end

    local function getTab(tabName: string)
        for _, tab in pairs(tabs) do
            if tab.Name == tabName then
                return tab
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
        containerFrame = tabbedWindowScreenGui.Container:Clone()
        backgroundFrame = containerFrame.Background
        containerMaid:GiveTask(containerFrame)

        if parent then
            tabbedWindow:Mount(parent)
        end

        -- Close
        closeButton = ExitButton.new(closeCallbackState)
        closeButton:Mount(backgroundFrame.CloseButton, true)
        closeButton.Pressed:Connect(function()
            tabbedWindow.ClosePressed:Fire()
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
    end

    function draw(updatedAlignment: boolean?)
        local queueNext = Queue.yield(tabbedWindow)

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

                    button = Button.new(textButton)
                    button.Pressed:Connect(function()
                        tabbedWindow:OpenTab(visibleTab.Name)
                    end)
                    visibleTab.Button = button
                end
                table.insert(newTabButtons, button)

                -- Update
                button:GetButtonObject().LayoutOrder = index
                button:GetButtonObject().Visible = not (openTabName == visibleTab.Name)

                -- Selected
                if openTabName == visibleTab.Name then
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
        end

        -- Window
        do
            -- Show/Hide Window Frames
            for _, tab in pairs(tabs) do
                if tab.WindowFrame then
                    tab.WindowFrame.Visible = openTabName == tab.Name
                end
            end

            -- Run Window Callback
            local openTab = getTab(openTabName)
            if openTab and openTab.WindowConstructor then
                openTab.WindowConstructor(backgroundFrame, drawMaid)
            end
        end

        queueNext()
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function tabbedWindow:Mount(newParent: GuiBase | GuiObject, hideParent: boolean?)
        parent = newParent
        containerFrame.Parent = parent

        if hideParent and parent:IsA("GuiObject") then
            parent.BackgroundTransparency = 1
        end
    end

    function tabbedWindow:GetContainer()
        return containerFrame
    end

    function tabbedWindow:OpenTab(tabName: string?)
        -- WARN: Bad tab
        local tab = getTab(tabName)
        if tabName and not tab then
            warn(("No tab %q exits"):format(tabName))
            return
        end

        openTabName = tabName
        openTabNameByTabIndex[tabsIndex] = tabName or openTabNameByTabIndex[tabsIndex]

        draw()
    end

    function tabbedWindow:AddTab(tabName: string, imageId: string)
        -- WARN: Already exists
        if getTab(tabName) then
            warn(("%q already exists!"):format(tabName))
            return
        end

        local tab: Tab = {
            Name = tabName,
            ImageId = imageId,
        }
        table.insert(tabs, tab)

        -- EDGE CASE: Select only tab
        if #tabs == 1 then
            tabbedWindow:OpenTab(tabName)
            return
        end

        draw()
    end

    function tabbedWindow:RemoveTab(tabName: string)
        for index, tab in pairs(tabs) do
            if tab.Name == tabName then
                table.remove(tabs, index)
            end
        end

        -- Open a different tab if this was opened
        if openTabName == tabName then
            for _, someTab in pairs(tabs) do
                tabbedWindow:OpenTab(someTab.Name)
                return
            end
        end
        tabbedWindow:OpenTab()
    end

    -- Sets a function that will create our window when we need it
    function tabbedWindow:SetWindowConstructor(tabName: string, constructor: (parent: GuiObject, maid: typeof(Maid.new())) -> nil)
        -- WARN: Bad tab
        local tab = getTab(tabName)
        if not tab then
            warn(("No tab %q exits"):format(tabName))
            return
        end

        tab.WindowConstructor = constructor

        if openTabName == tabName then
            draw()
        end
    end

    -- Sets a frame as a window for a tab
    function tabbedWindow:MountWindow(tabName: string, windowFrame: Frame)
        -- WARN: Bad tab
        local tab = getTab(tabName)
        if not tab then
            warn(("No tab %q exits"):format(tabName))
            return
        end

        if tab.WindowFrame then
            tabbedWindow:ClearWindow(tabName)
        end

        windowFrame.Parent = backgroundFrame.Back
        tab.WindowFrame = windowFrame

        if openTabName == tabName then
            draw()
        end
    end

    function tabbedWindow:ClearWindow(tabName: string)
        -- WARN: Bad tab
        local tab = getTab(tabName)
        if not tab then
            warn(("No tab %q exits"):format(tabName))
            return
        end

        -- RETURN: No window frame
        local windowFrame = tab.WindowFrame
        if not windowFrame then
            return
        end

        windowFrame.Parent = nil :: Instance
        tab.WindowFrame = nil

        if openTabName == tabName then
            draw()
        end
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    -- Setup
    draw(true)

    return tabbedWindow
end

return TabbedWindow
