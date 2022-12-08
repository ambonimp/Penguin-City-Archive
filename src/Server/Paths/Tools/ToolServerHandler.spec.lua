local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
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

    -- ToolServerHandlers must be well named
    for _, toolHandlerModuleScript: ModuleScript in pairs(Paths.Server.Tools.ToolServerHandlers:GetChildren()) do
        if toolHandlerModuleScript:IsA("ModuleScript") then
            local toolCategoryName = StringUtil.chopEnd(toolHandlerModuleScript.Name, "ToolServerHandler")
            if toolCategoryName then
                if not ToolConstants.CategoryNames[toolCategoryName] and toolCategoryName ~= "Default" then
                    table.insert(issues, "ToolServerHandler %s is prefixed with an invalid tool category name")
                end
            else
                table.insert(issues, "ToolServerHandler %s is badly named. <TOOL_CATEGORY>ToolServerHandler")
            end
        end
    end

    return issues
end
