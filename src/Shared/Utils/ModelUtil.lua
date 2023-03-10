local ModelUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BasePartUtil = require(ReplicatedStorage.Shared.Utils.BasePartUtil)
local InstanceUtil = require(ReplicatedStorage.Shared.Utils.InstanceUtil)

local SCALE_MODEL_RELATIVE_CLASSNAMES = { "Attachment", "Bone" }
local SCALE_MODEL_WORLD_CLASSNAMES = { "BasePart" }

function ModelUtil.weld(model: Model)
    -- ERROR: No mainPart
    local mainPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if not mainPart then
        error(("Model %s has no BaseParts to weld!"):format(model:GetFullName()))
    end

    for _, descendant: BasePart in pairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant ~= mainPart then
            BasePartUtil.weld(mainPart, descendant)
        end
    end
end

function ModelUtil.unanchor(model: Model)
    for _, descendant: BasePart in pairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = false
        end
    end
end

function ModelUtil.anchor(model: Model)
    for _, descendant: BasePart in pairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
        end
    end
end

function ModelUtil.getWorldPivotToCenter(model: Model, center: CFrame, sizeOffset: Vector3?)
    sizeOffset = sizeOffset or Vector3.new()

    local cframe: CFrame, size: Vector3 = model:GetBoundingBox()
    return center * CFrame.new(cframe:PointToObjectSpace(model.WorldPivot.Position) + size * sizeOffset)
end

function ModelUtil.hide(model: Model, tweenInfo: TweenInfo?)
    for _, descendant in pairs(model:GetDescendants()) do
        InstanceUtil.hide(descendant, tweenInfo)
    end
end

function ModelUtil.show(model: Model, tweenInfo: TweenInfo?)
    for _, descendant in pairs(model:GetDescendants()) do
        InstanceUtil.show(descendant, tweenInfo)
    end
end

local function doScaleInstanceWorld(instance: Instance)
    for _, className in pairs(SCALE_MODEL_WORLD_CLASSNAMES) do
        if instance:IsA(className) then
            return true
        end
    end

    return false
end

local function doScaleInstancRelative(instance: Instance)
    for _, className in pairs(SCALE_MODEL_RELATIVE_CLASSNAMES) do
        if instance:IsA(className) then
            return true
        end
    end

    return false
end

--[[
    Will scale the given model by the passed scaleFactor.
    Pretty powerful; will consider Weld constraints, bones etc.. when resizing.
    - Only covers specific Roblox Instances that were needed when first implemented (Pet Zoo Pet Rigs). May need configuration for new
    instances e.g., old weld objects.
]]
function ModelUtil.scale(model: Model, scaleFactor: number)
    -- Get Pivot
    local pivot = model:GetPivot().Position

    local function getScaledRelativePosition(position: Vector3)
        return position * scaleFactor
    end

    local function getScaledWorldPosition(position: Vector3)
        local pivotToPosition = position - pivot
        local scaledPivotToPosition = pivotToPosition * scaleFactor
        return pivot + scaledPivotToPosition
    end

    -- Loop descendants
    for _, descendant in pairs(model:GetDescendants()) do
        if doScaleInstanceWorld(descendant) then
            descendant.CFrame = descendant.CFrame - descendant.Position + getScaledWorldPosition(descendant.Position)
            descendant.Size = descendant.Size * scaleFactor
        elseif doScaleInstancRelative(descendant) then
            descendant.Position = getScaledRelativePosition(descendant.Position)
        end
    end

    -- Modify pivot offset
    if model.PrimaryPart then
        local pivotOffset = model.PrimaryPart.PivotOffset
        local pivotOffsetPosition = getScaledRelativePosition(pivotOffset.Position)
        model.PrimaryPart.PivotOffset = CFrame.new(pivotOffsetPosition) * (pivotOffset - pivotOffset.Position)
    end
end

function ModelUtil.getGlobalExtentsSize(model: Model, offset: CFrame?)
    offset = if offset then offset.Rotation else CFrame.new()

    local extentSize = {}
    for _, axis in { "X", "Y", "Z" } do
        local min = math.huge
        local max = -math.huge

        for _, part in pairs(model:GetDescendants()) do
            -- CONTINUE: Descendant isn't a part
            if not part:IsA("BasePart") then
                continue
            end

            local cframe = CFrame.new(part.Position) * offset
            local size = BasePartUtil.getGlobalExtentsSize(part, offset) / 2
            local negativeSide = offset:PointToObjectSpace(cframe:PointToWorldSpace(-size))[axis]
            local positiveSide = offset:PointToObjectSpace(cframe:PointToWorldSpace(size))[axis]

            if negativeSide < min then
                min = negativeSide
            end
            if positiveSide > max then
                max = positiveSide
            end
        end

        extentSize[axis] = math.abs(max - min)
    end

    return Vector3.new(extentSize.X, extentSize.Y, extentSize.Z)
end

function ModelUtil.getAssemblyMass(model: Model)
    local totalMass = 0

    for _, basePart in pairs(model:GetChildren()) do
        if basePart:IsA("BasePart") then
            totalMass += basePart.Mass
        end
    end

    return totalMass
end

return ModelUtil
