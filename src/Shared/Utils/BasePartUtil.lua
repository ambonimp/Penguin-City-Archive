local BasePartUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InstanceUtil = require(ReplicatedStorage.Shared.Utils.InstanceUtil)
local SignedDistanceUtil = require(ReplicatedStorage.Shared.Utils.SignedDistanceUtil)

export type PsuedoBasePart = {
    Size: Vector3,
    CFrame: CFrame,
} | BasePart

local DEFAULT_DRAW_PART_BETWEEN_POINTS_THICKNESS = 0.5

local CORNERS = {
    Vector3.new(0.5, 0.5, 0.5),
    Vector3.new(0.5, -0.5, 0.5),
    Vector3.new(-0.5, 0.5, 0.5),
    Vector3.new(-0.5, -0.5, 0.5),
    Vector3.new(0.5, 0.5, -0.5),
    Vector3.new(0.5, -0.5, -0.5),
    Vector3.new(-0.5, 0.5, -0.5),
    Vector3.new(-0.5, -0.5, -0.5),
}

-- Returns the size of a part's selection box
function BasePartUtil.getGlobalExtentsSize(part: PsuedoBasePart, offset: CFrame?): Vector3
    offset = if offset then offset.Rotation else CFrame.new()

    local cframe = part.CFrame
    local size = part.Size

    local extentSize = {}
    for _, axis in { "X", "Y", "Z" } do
        local min = math.huge
        local max = -math.huge

        for _, corner in pairs(CORNERS) do
            local position = offset:PointToObjectSpace(cframe:PointToWorldSpace(size * corner))[axis]
            if position < min then
                min = position
            end
            if position > max then
                max = position
            end
        end

        extentSize[axis] = max - min
    end

    return Vector3.new(extentSize.X, extentSize.Y, extentSize.Z)
end

-- Get's the closest point on (part0) relative to (part1)
function BasePartUtil.closestPoint(part0: PsuedoBasePart, part1: PsuedoBasePart): Vector3
    local closestPoint: Vector3
    local minDistance: number = math.huge

    local origin: Vector3 = part0.CFrame.Position

    local part1Size: Vector3 = part1.Size
    local part1CFrame: CFrame = part1.CFrame
    for _, corner in pairs(CORNERS) do
        local closestPointToCorner = SignedDistanceUtil.getBoxClosestPoint(part0, part1CFrame:PointToWorldSpace(part1Size * corner))

        local distanceToCorner = (closestPointToCorner - origin).Magnitude
        if distanceToCorner < minDistance then
            minDistance = distanceToCorner
            closestPoint = closestPointToCorner
        end
    end

    return closestPoint
end

function BasePartUtil.drawPartBetweenPoints(p0: Vector3, p1: Vector3, thickness: number?)
    thickness = thickness or DEFAULT_DRAW_PART_BETWEEN_POINTS_THICKNESS

    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false

    local vector01 = p1 - p0
    part.CFrame = CFrame.new(p0, p1) -- Easy way to get the orientation we need
    part.Position = p0 + vector01 / 2
    part.Size = Vector3.new(0.5, 0.5, vector01.Magnitude)

    return part
end

-- Will return a random point that lies in/on the boundary of the given part
function BasePartUtil.getRandomPointInPart(part: BasePart)
    return (part.CFrame * CFrame.new(
        math.random(-part.Size.X / 2, part.Size.X / 2),
        math.random(part.Size.Y / 2, part.Size.Y / 2),
        math.random(-part.Size.Z / 2, part.Size.Z / 2)
    )).Position
end

function BasePartUtil.weld(mainPart: BasePart, otherPart: BasePart, parent: BasePart?, constraintType: string?)
    local constraint = Instance.new(constraintType or "WeldConstraint")
    constraint.Name = otherPart:GetFullName()
    constraint.Part0 = mainPart
    constraint.Part1 = otherPart
    constraint.Parent = parent or mainPart

    return constraint
end
---https://devforum.roblox.com/t/checking-if-a-part-is-in-a-cylinder-but-rotatable/1134952
local function isPointInCylinder(point: Vector3, cylinder: BasePart)
    local radius = math.min(cylinder.Size.Z, cylinder.Size.Y) * 0.5
    local height = cylinder.Size.X
    local relative = (point - cylinder.Position)

    local sProj = cylinder.CFrame.RightVector:Dot(relative)
    local vProj = cylinder.CFrame.RightVector * sProj
    local len = (relative - vProj).Magnitude

    return len <= radius and math.abs(sProj) <= (height * 0.5)
end

function BasePartUtil.isPointInPart(part: BasePart, point: Vector3)
    local shape: Enum.PartType = part:IsA("Part") and part.Shape or Enum.PartType.Block

    local vec = part.CFrame:PointToObjectSpace(point) -- point now in context of part
    local size = part.Size

    if shape == Enum.PartType.Block then
        return (math.abs(vec.X) <= size.X / 2) and (math.abs(vec.Y) <= size.Y / 2) and (math.abs(vec.Z) <= size.Z / 2)
    elseif shape == Enum.PartType.Ball then
        local radius = math.min(size.X / 2, math.min(size.Y / 2, size.Z / 2))
        return vec.Magnitude <= radius
    elseif shape == Enum.PartType.Cylinder then
        return isPointInCylinder(point, part)
    else
        error(("Lacking API; no check for Part of shape %q (%s)"):format(shape.Name, debug.traceback()))
    end
end

return BasePartUtil
