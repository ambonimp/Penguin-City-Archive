local TweenUtil = {}

local TweenService = game:GetService("TweenService")

-- Creates a tween, and automatically plays it
function TweenUtil.tween(instance: Instance, tweenInfo: TweenInfo, propertyTable: { [string]: any })
    local tween = TweenService:Create(instance, tweenInfo, propertyTable)
    tween:Play()

    return tween
end

return TweenUtil
