local CFrameUtil = {}

function CFrameUtil.setPosition(cframe: CFrame, position: Vector3)
    return cframe - cframe.Position + position
end

return CFrameUtil
