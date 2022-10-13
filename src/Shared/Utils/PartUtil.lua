local PartUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InstanceUtil = require(ReplicatedStorage.Shared.Utils.InstanceUtil)

local DEFAULT_DRAW_PART_BETWEEN_POINTS_THICKNESS = 0.5

function PartUtil.drawPartBetweenPoints(p0: Vector3, p1: Vector3, thickness: number?)
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
function PartUtil.getRandomPointInPart(part: BasePart)
    return (part.CFrame * CFrame.new(
        math.random(-part.Size.X / 2, part.Size.X / 2),
        math.random(part.Size.Y / 2, part.Size.Y / 2),
        math.random(-part.Size.Z / 2, part.Size.Z / 2)
    )).Position
end

function PartUtil.weld(mainPart: BasePart, otherPart: BasePart)
    return InstanceUtil.weld(mainPart, otherPart)
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

function PartUtil.isPointInPart(part: BasePart, point: Vector3)
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

return PartUtil
