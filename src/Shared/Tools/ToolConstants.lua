local ToolConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)

export type ToolItem = {
    Name: string,
    Price: number,
}

local categoryNames: { [string]: string } = {}
local tools: { [string]: { [string]: ToolItem } } = {}

for _, categoryModuleScript in pairs(ReplicatedStorage.Shared.Tools.Categories:GetChildren()) do
    local categoryName = StringUtil.chopEnd(categoryModuleScript.Name, "ToolConstants")
    if not categoryName then
        error(("%s has a bad name"):format(categoryModuleScript:GetFullName()))
    end

    local module: {
        Items: {
            [string]: { Name: string, Price: number },
        },
    } =
        require(categoryModuleScript)

    categoryNames[categoryName] = categoryName
    tools[categoryName] = module.Items
end

ToolConstants.Tools = tools
ToolConstants.CategoryNames = categoryNames

return ToolConstants
