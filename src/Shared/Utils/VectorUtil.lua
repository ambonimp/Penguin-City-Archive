local VectorUtil = {}

function VectorUtil.getUnit(vector: Vector2 | Vector3)
    if vector.Magnitude == 0 then
        return vector
    end

    return vector.Unit
end

-- Returns the angle (in degrees) between these 2 vectors [0, 180]
function VectorUtil.getAngle(v0: Vector2 | Vector3, v1: Vector2 | Vector3)
    local dotProduct = v0:Dot(v1)
    local magnitudes = v0.Magnitude * v1.Magnitude
    local theta = math.acos(math.clamp(dotProduct / magnitudes, -1, 1))

    return math.deg(theta)
end

-- Returns an angle between [0, 360]. *Should* be clockwise around v0. Not tested fully.
function VectorUtil.getVector2FullAngle(v0: Vector2, v1: Vector2)
    local angle = VectorUtil.getAngle(v0, v1)
    local v0tov1 = v1 - v0

    if v0tov1.X >= 0 then
        angle = -angle
    end

    return (angle + 360) % 360
end

return VectorUtil
