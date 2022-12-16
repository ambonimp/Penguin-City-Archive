local AttachmentUtil = {}

--[[
	If you query an attachment for it's cframe, you get it relative to its parent.
	This method gets the cframe relative to the world!
]]
function AttachmentUtil.getWorldCFrame(attachment: Attachment)
    local worldPosition = attachment.WorldPosition
    local worldOrientation = attachment.WorldOrientation
    local cframe = CFrame.new(worldPosition)
        * CFrame.fromOrientation(math.rad(worldOrientation.X), math.rad(worldOrientation.Y), math.rad(worldOrientation.Z))

    return cframe
end

--[[
    Will translate `attachment` to the same world cframe as `pivot`, within the context they are both under
]]
function AttachmentUtil.pivot(attachment: Attachment, pivot: Attachment)
    attachment.WorldPosition = pivot.WorldPosition
    attachment.WorldOrientation = pivot.WorldOrientation
end

return AttachmentUtil
