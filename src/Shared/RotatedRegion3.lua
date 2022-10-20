--[[
    Rotated Region3 originally made by EgoMoose. Similar to Region3 but it can have rotation.
]]
local RotatedRegion3 = {}

local PLANE_AMOUNT = 6
local VERTEX_AMOUNT = 8

function RotatedRegion3.new(cframe: CFrame, size: Vector3)
    local region = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local planes = {
        { n = cframe:VectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Top)), d = -size.Y / 2 },
        { n = cframe:VectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Bottom)), d = -size.Y / 2 },
        { n = cframe:VectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Left)), d = -size.X / 2 },
        { n = cframe:VectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Right)), d = -size.X / 2 },
        { n = cframe:VectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Front)), d = -size.Z / 2 },
        { n = cframe:VectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Back)), d = -size.Z / 2 },
    }

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    -- Calculates all vertices of a part.
    local function getPartVertices(part: BasePart)
        local halfSize = part.Size / 2
        local vertices: { Vector3 } = {}
        for x = -1, 1, 2 do
            for y = -1, 1, 2 do
                for z = -1, 1, 2 do
                    table.insert(vertices, (part.CFrame * CFrame.new(halfSize * Vector3.new(x, y, z))).p)
                end
            end
        end
        return vertices
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function region:GetCFrame()
        return cframe
    end

    function region:GetSize()
        return size
    end

    function region:IsPointInside(point: Vector3)
        local diff = point - cframe.p
        for i = 1, PLANE_AMOUNT do
            local plane = planes[i]
            if (diff:Dot(plane.n) + plane.d) >= 0 then
                return false
            end
        end
        return true
    end

    --[[
        Checks if a part is inside this region. Note this function checks all vertices of the part. To check just its center, use IsInside instead.
        Does *not* check plane intersections.
    ]]
    function region:IsPartInside(part: BasePart)
        local vertices = getPartVertices(part)
        for i = 1, VERTEX_AMOUNT do
            local vertex = vertices[i]
            if self:IsInside(vertex) then
                return true
            end
        end
        return false
    end

    return region
end

function RotatedRegion3.fromPart(part: BasePart)
    return RotatedRegion3.new(part.CFrame, part.Size)
end

return RotatedRegion3
