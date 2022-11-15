local SledRaceUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModelUtil = require(ReplicatedStorage.Shared.Utils.ModelUtil)
local SledRaceConstants = require(ReplicatedStorage.Shared.Minigames.SledRace.SledRaceConstants)

local COLLECTABLE_TYPES = SledRaceConstants.Collectables

function SledRaceUtil.getMapOrigin(map: Model): CFrame
    local primaryPart: BasePart = map:WaitForChild("Origin")
    return primaryPart.CFrame:ToWorldSpace(CFrame.new(Vector3.new(0, 0.5, -0.5) * primaryPart.Size))
end

function SledRaceUtil.getSlopeBoundingBox(map: Model): (Vector3, CFrame)
    local slope: Model = map.Slope
    local direction: CFrame = SledRaceUtil.getMapOrigin(map).Rotation
    return ModelUtil.getGlobalExtentsSize(slope, direction), CFrame.new(slope:GetBoundingBox().Position) * direction
end

function SledRaceUtil.collectableIsA(collectable, collectableType: string): boolean
    local typeInfo = COLLECTABLE_TYPES[collectableType]
    if typeInfo then
        return collectable:GetAttribute("CollectableType") == typeInfo.Tag
    else
        return false
    end
end

function SledRaceUtil.getSled(player: Player): Model?
    return player.Character:FindFirstChild(SledRaceConstants.SledName)
end

function SledRaceUtil.unanchorSled(player)
    SledRaceUtil.getSled(player).PrimaryPart.Anchored = false
end

return SledRaceUtil
