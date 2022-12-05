local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Signal = require(Paths.Shared.Signal)
local ToolConstants = require(Paths.Shared.Tools.ToolConstants)
local ToolUtil = require(Paths.Shared.Tools.ToolUtil)
local Assume = require(Paths.Shared.Assume)
local Remotes = require(Paths.Shared.Remotes)
local Scope = require(Paths.Shared.Scope)
local Products = require(Paths.Shared.Products.Products)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local StringUtil = require(Paths.Shared.Utils.StringUtil)

return function()
    local issues: { string } = {}

    -- ToolClientHandlers must be well named
    for _, toolHandlerModuleScript: ModuleScript in pairs(Paths.Client.Tools.ToolClientHandlers:GetChildren()) do
        if toolHandlerModuleScript:IsA("ModuleScript") then
            local toolCategoryName = StringUtil.chopEnd(toolHandlerModuleScript.Name, "ToolClientHandler")
            if toolCategoryName then
                if not ToolConstants.CategoryNames[toolCategoryName] and toolCategoryName ~= "Default" then
                    table.insert(issues, "ToolClientHandler %s is prefixed with an invalid tool category name")
                end
            else
                table.insert(issues, "ToolClientHandler %s is badly named. <TOOL_CATEGORY>ToolClientHandler")
            end
        end
    end

    return issues
end
