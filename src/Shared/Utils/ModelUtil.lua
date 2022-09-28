local ModelUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenUtil = require(ReplicatedStorage.Shared.Utils.TweenUtil)

local ATTRIBUTE_CACHED_TRANSPARENCY = "_ModelUtilCachedTransparency"

function ModelUtil.weld(model: Model)
    -- ERROR: No mainPart
    local mainPart = model.PrimaryPart or model:FindFirstChildOfClass("BasePart")
    if not mainPart then
        error(("Model %s has no BaseParts to weld!"):format(model:GetFullName()))
    end

    for _, descendant: BasePart in pairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant ~= mainPart then
            local weldConstraint = Instance.new("WeldConstraint")
            weldConstraint.Name = descendant:GetFullName()
            weldConstraint.Part0 = mainPart
            weldConstraint.Part1 = descendant
            weldConstraint.Parent = mainPart
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

function ModelUtil.hide(model: Model, tweenInfo: TweenInfo?)
    for _, descendant: BasePart in pairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local cacheTransparency = descendant.Transparency

            if tweenInfo then
                TweenUtil.tween(descendant, tweenInfo, { Transparency = 1 })
            else
                descendant.Transparency = 1
            end

            -- Cache transparency (being careful not to overwrite)
            if not descendant:GetAttribute(ATTRIBUTE_CACHED_TRANSPARENCY) then
                descendant:SetAttribute(ATTRIBUTE_CACHED_TRANSPARENCY, cacheTransparency)
            end
        end
    end
end

function ModelUtil.show(model: Model, tweenInfo: TweenInfo?)
    for _, descendant: BasePart in pairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local cachedTransparency = descendant:GetAttribute(ATTRIBUTE_CACHED_TRANSPARENCY)
            if cachedTransparency then
                if tweenInfo then
                    TweenUtil.tween(descendant, tweenInfo, { Transparency = cachedTransparency })
                else
                    descendant.Transparency = cachedTransparency
                end

                descendant:SetAttribute(ATTRIBUTE_CACHED_TRANSPARENCY, nil)
            end
        end
    end
end

return ModelUtil
