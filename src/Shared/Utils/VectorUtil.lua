local VectorUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)

function VectorUtil.ifNanThen0(vector: Vector3): Vector3
    local x, y, z = vector.X, vector.Y, vector.Z
    if x ~= x or x == math.huge or x == -math.huge then
        x = 0
    end
    if y ~= y or y == math.huge or y == -math.huge then
        y = 0
    end
    if z ~= z or z == math.huge or z == -math.huge then
        z = 0
    end

    return Vector3.new(x, y, z)
end

function VectorUtil.round(vector: Vector3, decimals: number)
    return Vector3.new(MathUtil.round(vector.X, decimals), MathUtil.round(vector.Y, decimals), MathUtil.round(vector.Z, decimals))
end

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

function VectorUtil.getXZComponents(vector3: Vector3)
    return Vector3.new(vector3.X, 0, vector3.Z)
end

return VectorUtil
