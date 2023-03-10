--[[
    Class where we can define a hitbox by 1 or more of both/either parts/regions
]]
local Hitbox = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RotatedRegion3 = require(ReplicatedStorage.Shared.RotatedRegion3)
local Signal = require(ReplicatedStorage.Shared.Signal)
local Maid = require(ReplicatedStorage.Packages.maid)
local BasePartUtil = require(ReplicatedStorage.Shared.Utils.BasePartUtil)

local EPSILON = 0.001

function Hitbox.new()
    local hitbox = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local parts: { BasePart } = {}
    local rotatedRegions: { typeof(RotatedRegion3.new(CFrame.new(), Vector3.new())) } = {}
    local maid = Maid.new()
    local isDestroyed = false

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    hitbox.PartAdded = Signal.new() -- {part: Part}

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function hitbox:GetMaid()
        return maid
    end

    function hitbox:AddPart(part: BasePart)
        -- RETURN: Already added
        if table.find(parts, part) then
            return
        end

        table.insert(parts, part)
        hitbox.PartAdded:Fire(part)

        return hitbox
    end

    function hitbox:AddParts(addParts: { BasePart })
        for _, part in pairs(addParts) do
            hitbox:AddPart(part)
        end

        return hitbox
    end

    function hitbox:AddRotatedRegion3(rotatedRegion: typeof(RotatedRegion3.new(CFrame.new(), Vector3.new())))
        -- RETURN: Already added
        local cframe = rotatedRegion:GetCFrame()
        for _, otherRotatedRegion in pairs(rotatedRegions) do
            local otherCFrame = otherRotatedRegion:GetCFrame()

            local cframePosDif = (cframe.Position - otherCFrame.Position).Magnitude
            local cframeRotDotProduct = (cframe.LookVector:Dot(otherCFrame.LookVector))
            local sizeDif = (rotatedRegion:GetSize() - otherRotatedRegion:GetSize()).Magnitude

            local samePosition = cframePosDif <= EPSILON
            local sameRotation = (1 - cframeRotDotProduct) <= EPSILON
            local sameSize = sizeDif <= EPSILON

            if samePosition and sameRotation and sameSize then
                return
            end
        end

        table.insert(rotatedRegions, rotatedRegion)

        return hitbox
    end

    function hitbox:AddRegion(cframe: CFrame, size: Vector3)
        hitbox:AddRotatedRegion3(RotatedRegion3.new(cframe, size))
    end

    function hitbox:IsPointInside(point: Vector3)
        -- Check rotated regions.
        for _, rotatedRegion in pairs(rotatedRegions) do
            if rotatedRegion:IsPointInside(point) then
                return true
            end
        end

        -- Check parts
        for _, part in pairs(parts) do
            if BasePartUtil.isPointInPart(part, point) then
                return true
            end
        end

        return false
    end

    --[[
        Returns true if `part` is inside this Hitbox.

        !! Will not detect if `part` is inside a defined interal region; only inside a defined internal part
    ]]
    function hitbox:IsPartInside(part: BasePart)
        for _, hitboxPart in pairs(parts) do
            local partsInPart = Workspace:GetPartsInPart(hitboxPart)
            if table.find(partsInPart, part) then
                return true
            end
        end

        return false
    end

    function hitbox:Destroy(doDestroyParts: boolean?)
        if isDestroyed then
            return
        end
        isDestroyed = true

        maid:Destroy()

        if doDestroyParts then
            for _, part in pairs(parts) do
                part:Destroy()
            end
        end
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    -- Cleanup
    maid:GiveTask(hitbox.PartAdded)

    return hitbox
end

return Hitbox
