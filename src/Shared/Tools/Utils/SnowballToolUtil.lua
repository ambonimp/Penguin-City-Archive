local SnowballToolUtil = {}

function SnowballToolUtil.hideSnowball(snowballModel: Model)
    snowballModel.PrimaryPart.Transparency = 1
end

function SnowballToolUtil.showSnowball(snowballModel: Model)
    snowballModel.PrimaryPart.Transparency = 0
end

return SnowballToolUtil
