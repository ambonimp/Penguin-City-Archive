local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolConstants = require(ReplicatedStorage.Shared.Tools.ToolConstants)
local ToolUtil = require(ReplicatedStorage.Shared.Tools.ToolUtil)

return function()
    local issues: { string } = {}

    -- Constants
    do
        for categoryName, tools in pairs(ToolConstants.Tools) do
            for toolKey, tool in pairs(tools) do
                -- Name much match key
                if toolKey ~= tool.Name then
                    table.insert(issues, ("%s.%s toolKey does not match .Name (%s)"):format(categoryName, toolKey, tool.Name))
                end
            end

            -- Banned names
            if categoryName == "Default" then
                table.insert(issues, "'Default' is a banned tool category name!")
            end
        end
    end

    -- Models
    do
        for categoryName, tools in pairs(ToolConstants.Tools) do
            for _, tool in pairs(tools) do
                local success, model = pcall(ToolUtil.getModel, ToolUtil.tool(categoryName, tool.Name))
                if success then
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
                else
                    table.insert(issues, ("Tool %s.%s has not model"):format(categoryName, tool.Name))
                end
            end
        end
    end

    return issues
end
