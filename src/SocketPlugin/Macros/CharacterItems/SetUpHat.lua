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
    Name = "Setup Hat",
    Group = "Character Items",
    Icon = "💡",
    Description = "Configures a hat item for use in game. Must have the starter character model in Workspace.",
}

macroDefinition.Function = function()
    local selection = Selection:Get()[1]
    assert(selection:IsA("Model"), "Item must be a model")

    local character = assert(Workspace:FindFirstChild("StarterCharacter"), "Starter character can't be found in workspace")

    local handle = selection:FindFirstChild("Handle")
        or selection:FindFirstChildOfClass("BasePart")
        or selection:FindFirstChildOfClass("MeshPart")

    for _, child in pairs(selection:GetChildren()) do
        child.Name = if child.Name == "Handle" then "Part" else child.Name
        for _, descendant in pairs(child:GetChildren()) do
            descendant:Destroy()
        end

        if child == handle then
            handle.Name = "Handle"
            local attachment = Instance.new("Attachment")
            attachment.Parent = handle
            attachment.WorldCFrame = character.Body.Main_Bone.Belly["Belly.001"].HEAD.WorldCFrame
            attachment.Name = "HatAttachment"
        end
    end

    ChangeHistoryService:SetWaypoint("Setup Hat")
end

return macroDefinition
