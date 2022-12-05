local SnowballToolUtil = {}

function SnowballToolUtil.hideSnowball(snowballModel: Model)
    snowballModel.PrimaryPart.Transparency = 1
end

function SnowballToolUtil.showSnowball(snowballModel: Model)
    snowballModel.PrimaryPart.Transparency = 0
end

function SnowballToolUtil.matchSnowball(snowballModel: Model, oldSnowballModel: Model)
    snowballModel.PrimaryPart.Transparency = oldSnowballModel.PrimaryPart.Transparency
end

return SnowballToolUtil
