local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local ZoneUtil = require(ReplicatedStorage.Shared.Zones.ZoneUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

return function()
    local issues: { string } = {}

    -- Streaming
    do
        -- Must be enabled
        if not game.Workspace.StreamingEnabled then
            table.insert(issues, "StreamingEnabled is StreamingDisabled! Set that to true")
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
        for zoneType, zoneIds in pairs(ZoneConstants.ZoneId) do
            for _, zoneId in pairs(zoneIds) do
                local zoneModel = ZoneUtil.getZoneModel(ZoneUtil.zone(zoneType, zoneId))

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
                        (("Zone %s %s has more than one tagged WaterAnimatorInstance (%s)"):format(zoneType, zoneId, foundList))
                    )
                end
            end
        end
    end

    return issues
end
