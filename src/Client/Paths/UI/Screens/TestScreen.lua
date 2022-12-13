local TestScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local SelectionPanel = require(Paths.Client.UI.Elements.SelectionPanelTest)

local TAB_NAME = "WHOA"

local selectionPanel = SelectionPanel.new()
-- selectionPanel:SetAlignment("Bottom")
selectionPanel:SetSize(9, 1)
selectionPanel:AddTab(TAB_NAME, "")
selectionPanel:Mount(Paths.UI.CharacterEditor)

for i = 1, 10 do
    local widgetName = tostring(i)
    selectionPanel:AddWidgetConstructor(TAB_NAME, widgetName, false, function(widget)
        widget:SetText(widgetName, true)
    end)
end

return TestScreen
