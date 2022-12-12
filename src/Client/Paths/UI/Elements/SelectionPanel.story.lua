local SelectionPanel = require(script.Parent.SelectionPanelTest)

return function(target)
    local selectionPanel = SelectionPanel.new()
    selectionPanel:SetAlignment("Left")
    selectionPanel:SetSize(10, 4)
    selectionPanel:Mount(target)

    return function()
        selectionPanel:Destroy()
    end
end
