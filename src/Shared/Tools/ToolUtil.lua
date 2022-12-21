local ToolUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolConstants = require(ReplicatedStorage.Shared.Tools.ToolConstants)
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)

export type Tool = {
    CategoryName: string,
    ToolId: string,
}

local HAND_BONE_NAME = "Hand.R"
local TOOL_METATABLE = {
    __eq = function(tool1, tool2)
        return ToolUtil.toolsMatch(tool1, tool2)
    end,
}

-------------------------------------------------------------------------------
-- Private Methods
-------------------------------------------------------------------------------

local function getToolModelName(tool: Tool)
    return ("%s_%s"):format(tool.CategoryName, tool.ToolId)
end

-------------------------------------------------------------------------------
-- Public Methods
-------------------------------------------------------------------------------

function ToolUtil.tool(categoryName: string, toolName: string)
    -- ERROR: Bad categoryName/toolName
    if not (ToolConstants.Tools[categoryName] and ToolConstants.Tools[categoryName][toolName]) then
        error(("Bad categoryName/toolName combo %q %q"):format(categoryName, toolName))
    end

    local tool = setmetatable({
        CategoryName = categoryName,
        ToolId = toolName,
    }, TOOL_METATABLE) :: Tool

    return tool
end

function ToolUtil.toolsMatch(tool1: Tool, tool2: Tool)
    return tool1.CategoryName == tool2.CategoryName and tool1.ToolId == tool2.ToolId
end

--[[
    Returns direct reference. Use :Clone() !
]]
function ToolUtil.getModel(tool: Tool): Model
    return ReplicatedStorage.Assets.Tools[tool.CategoryName][tool.ToolId]
end

function ToolUtil.getModelFromCharacter(tool: Tool, character: Model): Model | nil
    return character:FindFirstChild(getToolModelName(tool))
end

--[[
    Has `character` hold a `toolName` model

    Returns the model.
]]
function ToolUtil.hold(character: Model, tool: Tool): Model
    -- ERROR: No hand bone found!
    local handBone = character:FindFirstChild(HAND_BONE_NAME, true)
    if not (handBone and handBone:IsA("Bone")) then
        error(("Could not find HandBone %q in character %s (%s)"):format(HAND_BONE_NAME, character:GetFullName(), tostring(handBone)))
    end

    local toolModel = ToolUtil.getModel(tool):Clone()
    toolModel.Name = getToolModelName(tool)

    local toolAttachment = toolModel.PrimaryPart:FindFirstChildOfClass("Attachment")

    local rigidConstraint = Instance.new("RigidConstraint")
    rigidConstraint.Attachment0 = toolAttachment
    rigidConstraint.Attachment1 = handBone
    rigidConstraint.Parent = toolModel.PrimaryPart

    toolModel.Parent = character

    return toolModel
end

function ToolUtil.canEquipToolInZone(zone: ZoneConstants.Zone)
    return zone.ZoneCategory == ZoneConstants.ZoneCategory.Room
end

return ToolUtil
