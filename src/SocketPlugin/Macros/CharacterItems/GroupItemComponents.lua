---
-- Macro
---

--------------------------------------------------
-- Dependencies
local Selection = game:GetService("Selection")
local Workspace = game:GetService("Workspace")

--------------------------------------------------
-- Members
local macroDefinition = {
    Name = "Group Item Components",
    Group = "Character Items",
    Icon = "💡",
    Description = "Export pieces of an item out of their manequin and bundles them correctly",
    EnableAutomaticUndo = true,
}

macroDefinition.Function = function()
    local components = Selection:Get()

    local model = Instance.new("Model")
    model.Parent = Workspace

    for _, component in pairs(components) do
        if component:IsA("BasePart") or component:IsA("MeshPart") then
            component.Parent = model
            for _, child in pairs(component:GetChildren()) do
                if child:IsA("WeldConstraint") then
                    child:Destroy()
                end
            end
        end
    end

    Selection:Set({ model })
end

return macroDefinition
