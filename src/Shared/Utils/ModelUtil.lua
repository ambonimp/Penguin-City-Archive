local ModelUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenUtil = require(ReplicatedStorage.Shared.Utils.TweenUtil)
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
            InstanceUtil.weld(mainPart, descendant)
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

return ModelUtil
