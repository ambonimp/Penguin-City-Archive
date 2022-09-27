local VectorUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)

function VectorUtil.round(vector: Vector3, decimals: number)
    return Vector3.new(MathUtil.round(vector.X, decimals), MathUtil.round(vector.Y, decimals), MathUtil.round(vector.Z, decimals))
end

return VectorUtil
