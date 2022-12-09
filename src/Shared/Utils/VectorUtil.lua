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

return VectorUtil
