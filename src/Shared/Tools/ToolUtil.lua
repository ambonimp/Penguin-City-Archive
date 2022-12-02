local ToolUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolConstants = require(ReplicatedStorage.Shared.Tools.ToolConstants)

export type Tool = {
    CategoryName: string,
    ToolName: string,
}

local HAND_BONE_NAME = "Hand.R"

function ToolUtil.tool(categoryName: string, toolName: string)
    -- ERROR: Bad categoryName/toolName
    if not (ToolConstants.ToolNames[categoryName] and ToolConstants.ToolNames[categoryName][toolName]) then
        error(("Bad categoryName/toolName combo %q %q"):format(categoryName, toolName))
    end

    local tool: Tool = {
        CategoryName = categoryName,
        ToolName = toolName,
    }
    return tool
end

--[[
    Returns direct reference. Use :Clone() !
]]
function ToolUtil.getModel(tool: Tool): Model
    return ReplicatedStorage.Assets.Tools[tool.CategoryName][tool.ToolName]
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
    local toolAttachment = toolModel.PrimaryPart:FindFirstChildOfClass("Attachment")

    local rigidConstraint = Instance.new("RigidConstraint")
    rigidConstraint.Attachment0 = toolAttachment
    rigidConstraint.Attachment1 = handBone
    rigidConstraint.Parent = toolModel.PrimaryPart

    toolModel.Parent = character

    return toolModel
end

return ToolUtil
