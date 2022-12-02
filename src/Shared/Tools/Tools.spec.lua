local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolConstants = require(ReplicatedStorage.Shared.Tools.ToolConstants)
local ToolUtil = require(ReplicatedStorage.Shared.Tools.ToolUtil)

return function()
    local issues: { string } = {}

    -- Models
    do
        for categoryName, toolNames in pairs(ToolConstants.ToolNames) do
            for _, toolName in pairs(toolNames) do
                local model = ToolUtil.getModel(categoryName, toolName)

                -- need PrimaryPart with Attachment
                if model.PrimaryPart then
                    local attachment = model.PrimaryPart:FindFirstChildWhichIsA("Attachment")
                    if not attachment then
                        table.insert(issues, ("ToolModel PrimaryPart %s needs an attachment"):format(model.PrimaryPart:GetFullName()))
                    end
                else
                    table.insert(issues, ("ToolModel %s needs PrimaryPart"):format(model:GetFullName()))
                end

                -- Must be unanchored.
                for _, descendant: Instance | BasePart in pairs(model:GetDescendants()) do
                    if descendant:IsA("BasePart") and descendant.Anchored then
                        table.insert(issues, ("ToolModel %s has anchored part %s"):format(model.Name, descendant:GetFullName()))
                    end
                end
            end
        end
    end

    return issues
end
