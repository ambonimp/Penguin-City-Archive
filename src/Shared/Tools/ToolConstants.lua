local ToolConstants = {}

-------------------------------------------------------------------------------
-- Internal Methods
-------------------------------------------------------------------------------

-- Gets our constants directly out of studio
local function getTools()
    local tools = setmetatable({}, {
        __index = function(_, index)
            warn(("Bad RoomId %q"):format(index))
        end,
    }) :: { [string]: string }

    local toolsFolder: Folder = game.ReplicatedStorage.Assets.Tools
    for _, child in pairs(toolsFolder:GetChildren()) do
        local toolName = child.Name
        if tools[toolName] then
            error(("Duplicate tool name %q"):format(toolName))
        end

        tools[toolName] = toolName
    end

    return tools
end

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

ToolConstants.ToolNames = getTools()

return ToolConstants
