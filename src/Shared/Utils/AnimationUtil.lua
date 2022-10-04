local AnimationUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenUtil = require(ReplicatedStorage.Shared.Utils.TweenUtil)

-- Returns a function that can be called to stop the animation from playing
function AnimationUtil.animateTexture(
    texture: Texture,
    tweenInfos: { TileU: TweenInfo?, TileV: TweenInfo? },
    reverse: { TileU: boolean?, TileV: boolean? }?
)
    local tweenU: Tween?, tweenV: Tween?

    if tweenInfos.TileU then
        texture.OffsetStudsU = 0
        local scalar = reverse.TileU and -1 or 1
        tweenU = TweenUtil.tween(texture, tweenInfos.TileU, { OffsetStudsU = texture.StudsPerTileU * scalar })
    end
    if tweenInfos.TileV then
        texture.OffsetStudsV = 0
        local scalar = reverse.TileV and -1 or 1
        tweenV = TweenUtil.tween(texture, tweenInfos.TileV, { OffsetStudsV = texture.StudsPerTileV * scalar })
    end

    return function()
        if tweenU then
            tweenU:Cancel()
            tweenU:Destroy()
        end
        if tweenV then
            tweenV:Cancel()
            tweenV:Destroy()
        end
    end
end

return AnimationUtil
