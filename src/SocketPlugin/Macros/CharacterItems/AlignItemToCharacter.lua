---
-- Macro
---

--------------------------------------------------
-- Dependencies
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local Workspace = game:GetService("Workspace")

--------------------------------------------------
-- Members
local macroDefinition = {
    Name = "Align Item to Character",
    Group = "Character Items",
    Icon = "💡",
}

macroDefinition.Function = function()
    local item = Selection:Get()[1]
    assert(item:IsA("Model"), "Item must be a model")

    local character = assert(Workspace:FindFirstChild("StarterCharacter"), "Starter character can't be found in workspace")
    item:PivotTo(character.WorldPivot)

    ChangeHistoryService:SetWaypoint("Align Item Character")
end

return macroDefinition
