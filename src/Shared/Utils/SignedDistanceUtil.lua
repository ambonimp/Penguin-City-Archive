local SignedDistanceUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vector3Util = require(ReplicatedStorage.Shared.Utils.Vector3Util)

function SignedDistanceUtil.getBoxClosestPoint(box: BasePart, position: Vector3): Vector3
    local cframe = box.CFrame
    local offset = cframe:PointToObjectSpace(position)
    local size = box.Size / 2

    local positionDistanceFromClosestPoint = Vector3Util.max(Vector3Util.abs(offset) - size, Vector3.new())
    return cframe:PointToWorldSpace(offset - (positionDistanceFromClosestPoint * Vector3Util.sign(offset)))
end

return SignedDistanceUtil
