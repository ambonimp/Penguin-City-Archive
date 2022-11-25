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

return AttachmentUtil
