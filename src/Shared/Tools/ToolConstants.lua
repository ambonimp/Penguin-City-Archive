local ToolConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

-------------------------------------------------------------------------------
-- Internal Methods
-------------------------------------------------------------------------------

-- Gets our constants directly out of studio
local function getTools()
    local tools = setmetatable({}, {
        __index = function(_, index)
            warn(("Bad RoomId %q"):format(index))
        end,
    }) :: { [string]: { [string]: string } }

    local toolsFolder: Folder = game.ReplicatedStorage.Assets.Tools
    for _, categoryFolder in pairs(toolsFolder:GetChildren()) do
        local categoryName = categoryFolder.Name
        if tools[categoryName] then
            error(("Duplicate tool category name %q"):format(categoryName))
        end
        tools[categoryName] = {}

        for _, toolModel in pairs(categoryFolder:GetChildren()) do
            local toolName = toolModel.Name
            if tools[categoryName][toolName] then
                error(("Duplicate tool name %q"):format(toolName))
            end
            tools[categoryName][toolName] = toolName
        end
    end

    return tools
end

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

-- { [categoryName]: { [toolName]: toolName } }
ToolConstants.ToolNames = getTools()

-- { [categoryName]: categoryName }
ToolConstants.CategoryNames = TableUtil.enumFromKeys(ToolConstants.ToolNames) :: { [string]: string }

return ToolConstants
