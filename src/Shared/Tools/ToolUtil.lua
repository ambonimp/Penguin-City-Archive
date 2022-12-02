local ToolUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolConstants = require(ReplicatedStorage.Shared.Tools.ToolConstants)

local HAND_BONE_NAME = "Hand.R"

local function verifyToolName(toolName: string)
    if not ToolConstants.ToolNames[toolName] then
        error(("Bad ToolName %q"):format(toolName))
    end
end

--[[
    Returns direct reference. Use :Clone() !
]]
function ToolUtil.getModel(toolName: string): Model
    verifyToolName(toolName)

    return ReplicatedStorage.Assets.Tools[toolName]
end

--[[
    Has `character` hold a `toolName` model

    Returns the model.
]]
function ToolUtil.hold(character: Model, toolName: string): Model
    -- ERROR: No hand bone found!
    local handBone = character:FindFirstChild(HAND_BONE_NAME, true)
    if not (handBone and handBone:IsA("Bone")) then
        error(("Could not find HandBone %q in character %s (%s)"):format(HAND_BONE_NAME, character:GetFullName(), tostring(handBone)))
    end

    local toolModel = ToolUtil.getModel(toolName):Clone()
    local toolAttachment = toolModel.PrimaryPart:FindFirstChildOfClass("Attachment")

    local rigidConstraint = Instance.new("RigidConstraint")
    rigidConstraint.Attachment0 = toolAttachment
    rigidConstraint.Attachment1 = handBone
    rigidConstraint.Parent = toolModel.PrimaryPart

    toolModel.Parent = character

    return toolModel
end

return ToolUtil
