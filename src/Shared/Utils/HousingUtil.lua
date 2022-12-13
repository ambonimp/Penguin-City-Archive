local HousingUtil = {}

--Calculates a CFrame taking into account the normal of the surface an object is trying to be placed on
function HousingUtil.CalculateObjectCFrame(oldCf, surfacePos, normal)
    local oldUpVec = oldCf.UpVector
    local oldRot = oldCf - oldCf.Position
    local newPos = surfacePos -- + normal
    local dot = oldUpVec:Dot(normal)
    if dot > 1 - 1e-5 then
        return oldRot + newPos
    end
    if dot < -1 + 1e-5 then
        return CFrame.Angles(math.pi, 0, 0) * oldRot + newPos
    end
    local scalarAngle = math.acos(dot)
    local rotationAxis = oldUpVec:Cross(normal).Unit
    return CFrame.fromAxisAngle(rotationAxis, scalarAngle) * oldRot + newPos
end

return HousingUtil
