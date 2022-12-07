local Vector3Util = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)

function Vector3Util.ifNanThen0(vector: Vector3): Vector3
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

function Vector3Util.max(vector1: Vector3, vector2: Vector3): Vector3
    return Vector3.new(math.max(vector1.X, vector2.X), math.max(vector1.Y, vector2.Y), math.max(vector1.Z, vector2.Z))
end

function Vector3Util.abs(vector: Vector3): Vector3
    return Vector3.new(math.abs(vector.X), math.abs(vector.Y), math.abs(vector.Z))
end

function Vector3Util.sign(vector: Vector3): Vector3
    return Vector3.new(math.sign(vector.X), math.sign(vector.Y), math.sign(vector.Z))
end

function Vector3Util.floor(vector: Vector3)
    return Vector3.new(math.floor(vector.X), math.floor(vector.Y), math.floor(vector.Z))
end

function Vector3Util.round(vector: Vector3, decimals: number)
    return Vector3.new(MathUtil.round(vector.X, decimals), MathUtil.round(vector.Y, decimals), MathUtil.round(vector.Z, decimals))
end

function Vector3Util.getXZComponents(vector3: Vector3)
    return Vector3.new(vector3.X, 0, vector3.Z)
end

--[[
    Returns a Vector3 with internalRandom numbers in all axes.
]]
function Vector3Util.nextVector(min: number, max: number)
    local x = MathUtil.nextNumber(min, max)
    local y = MathUtil.nextNumber(min, max)
    local z = MathUtil.nextNumber(min, max)
    return Vector3.new(x, y, z)
end

return Vector3Util
