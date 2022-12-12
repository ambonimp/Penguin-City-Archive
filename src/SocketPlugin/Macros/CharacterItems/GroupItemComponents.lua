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
    Name = "Group Item Components",
    Group = "Character Items",
    Icon = "💡",
    Description = "Export pieces of an item out of their manequin and bundles them correctly",
}

macroDefinition.Function = function()
    local components = Selection:Get()

    local model = Instance.new("Model")
    model.Parent = Workspace

    for _, component in pairs(components) do
        if component:IsA("BasePart") or component:IsA("MeshPart") then
            local origin = component.Parent.Penguin_body.Main_Bone.WorldCFrame
            local offset = origin:ToObjectSpace(component.CFrame)

            local lastSize = component.Size

            component.Parent = model

            task.defer(function()
                component.CFrame = origin:ToWorldSpace(offset)
                component.Size = lastSize

                component:ClearAllChildren()
            end)
        end
    end

    ChangeHistoryService:SetWaypoint("Align Item Character")
end

return macroDefinition
