local VectorUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)

--[[
    Returns a Vector3 with internalRandom numbers in all axes.
]]
function VectorUtil.nextVector3(min: number, max: number)
    return MathUtil.nextVector3(min, max)
end

function VectorUtil.getUnit(vector: Vector2 | Vector3)
    if vector.Magnitude == 0 then
        return vector
    end

    return vector.Unit
end

return VectorUtil
