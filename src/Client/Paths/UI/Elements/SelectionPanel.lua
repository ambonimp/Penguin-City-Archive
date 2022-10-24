--[[
    Selection widget with different tabs with scrolling frames
]]
local SelectionPanel = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIElement = require(script.Parent.UIElement)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

SelectionPanel.Defaults = {
    Alignment = "Right",
    Size = 1,
}

function SelectionPanel.new()
    local selectionPanel = UIElement.new()

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local alignment: "Left" | "Right" | "Top" | "Bottom" = SelectionPanel.Defaults.Alignment
    local size = SelectionPanel.Defaults.Size

    local tabs: { [string]: {
        ImageId: string,
        Widgets: { [string]: {
            ImageId: string,
        } },
    } } =
        {}
    local openTabName: string | nil

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function draw()
        --todo
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function selectionPanel:OpenTab(tabName: string?)
        openTabName = tabName

        draw()
    end

    function selectionPanel:SetAlignment(newAlignmnet: "Left" | "Right" | "Top" | "Bottom")
        alignment = newAlignmnet

        draw()
    end

    -- Sets the row/column count (depends on alignment)
    function selectionPanel:SetSize(newSize: number)
        size = newSize

        draw()
    end

    function selectionPanel:AddTab(tabName: string, imageId: string)
        -- WARN: Already exists
        if tabName[tabName] then
            warn(("%q already exists!"):format(tabName))
            return
        end

        tabs[tabName] = {
            ImageId = imageId,
            Widgets = {},
        }

        -- Select first tab
        if TableUtil.length(tabs) == 1 then
            selectionPanel:OpenTab(tabName)
        end

        draw()
    end

    function selectionPanel:RemoveTab(tabName: string)
        tabs[tabName] = nil

        -- Open a different tab if this was opened
        if openTabName == tabName then
            for someTabName, _ in pairs(tabs) do
                selectionPanel:OpenTab(someTabName)
                return
            end
        end
        selectionPanel:OpenTab()
    end

    function selectionPanel:AddWidget(tabName: string, widgetName: string, imageId: string)
        -- WARN: Bad tab
        local tab = tabs[tabName]
        if not tab then
            warn(("No tab %q exits"):format(tabName))
            return
        end

        -- WARN: Already exists
        if tab.Widgets[widgetName] then
            warn(("Widget %s.%s already exists!"):format(tabName, widgetName))
            return
        end

        tab.Widgets[widgetName] = {
            ImageId = imageId,
        }

        draw()
    end

    function selectionPanel:RemoveWidget(tabName: string, widgetName: string)
        -- WARN: Bad tab
        local tab = tabs[tabName]
        if not tab then
            warn(("No tab %q exits"):format(tabName))
            return
        end

        tab.Widgets[widgetName] = nil

        draw()
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    draw()

    return selectionPanel
end

return SelectionPanel
