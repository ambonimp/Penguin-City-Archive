local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local ZoneUtil = require(ReplicatedStorage.Shared.Zones.ZoneUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local DescendantLooper = require(ReplicatedStorage.Shared.DescendantLooper)

return function()
    local issues: { string } = {}

    -- Streaming
    do
        -- Must be enabled
        if not game.Workspace.StreamingEnabled then
            table.insert(issues, "StreamingEnabled is StreamingDisabled! Set that to true")
        end
    end

    -- Boundaries must be anchored + collideable!
    do
        for zoneCategory, zoneTypes in pairs(ZoneConstants.ZoneType) do
            for _, zoneType in pairs(zoneTypes) do
                local zoneModel = ZoneUtil.getZoneModel(ZoneUtil.zone(zoneCategory, zoneType))
                local boundariesFolder = zoneModel and zoneModel:FindFirstChild("Boundaries")
                if boundariesFolder then
                    for _, descendant: BasePart in pairs(boundariesFolder:GetDescendants()) do
                        if descendant:IsA("BasePart") and not (descendant.Anchored and descendant.CanCollide) then
                            table.insert(
                                issues,
                                (("Boundary BasePart %s must be anchored and collideable!"):format(descendant:GetFullName()))
                            )
                        end
                    end
                end
            end
        end
    end

    -- WaterAnimator
    do
        -- Must only be models
        local WaterAnimatorInstances = CollectionService:GetTagged(ZoneConstants.Cosmetics.Tags.WaterAnimator)
        for _, WaterAnimatorInstance in pairs(WaterAnimatorInstances) do
            if not WaterAnimatorInstance:IsA("Model") then
                table.insert(issues, (("WaterAnimator Instance %s must be a Model"):format(WaterAnimatorInstance:GetFullName())))
            end
        end

        -- Each zoneModel must have 0 or 1 WaterAnimator instances
        for _, zoneType in pairs(ZoneConstants.ZoneType.Room) do
            local zoneModel = ZoneUtil.getZoneModel(ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, zoneType))

            local foundWaterInstances: { Instance } = {}
            for _, WaterAnimatorInstance in pairs(WaterAnimatorInstances) do
                if WaterAnimatorInstance:IsDescendantOf(zoneModel) then
                    table.insert(foundWaterInstances, WaterAnimatorInstance)
                end
            end

            if #foundWaterInstances > 1 then
                local foundList = table.concat(
                    TableUtil.mapValues(foundWaterInstances, function(foundWaterInstance: Instance)
                        return foundWaterInstance:GetFullName()
                    end),
                    ", "
                )

                table.insert(
                    issues,
                    (
                        ("Zone %s %s has more than one tagged ZoneWaterInstance (%s)"):format(
                            ZoneConstants.ZoneCategory.Room,
                            zoneType,
                            foundList
                        )
                    )
                )

                table.insert(
                    issues,
                    (("Zone %s %s has more than one tagged WaterAnimatorInstance (%s)"):format(zoneType, zoneType, foundList))
                )
            end
        end
    end

    return issues
end
