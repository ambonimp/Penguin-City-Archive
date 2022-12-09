local VectorUtil = {}

function VectorUtil.getUnit(vector: Vector2 | Vector3)
    if vector.Magnitude == 0 then
        return vector
    end

    return vector.Unit
end

return VectorUtil
