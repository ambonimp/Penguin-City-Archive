local CFrameUtil = {}

function CFrameUtil.ifNanThen0(cframe: CFrame): CFrame
    return if cframe ~= cframe then CFrame.new() else cframe
end

function CFrameUtil.yComponent(cframe: CFrame, method: string?): number
    local _, y = cframe["ToEulerAnglesYXZ" or method](cframe)
    return y :: number
end

return CFrameUtil
