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

    -- ZoneWater
    do
        -- Must only be models
        local zoneWaterInstances = CollectionService:GetTagged(ZoneConstants.CollectionTagZoneWater)
        for _, zoneWaterInstance in pairs(zoneWaterInstances) do
            if not zoneWaterInstance:IsA("Model") then
                table.insert(issues, (("ZoneWater Instance %s must be a Model"):format(zoneWaterInstance:GetFullName())))
            end
        end

        -- Each zoneModel must have 0 or 1 zoneWater instances
        for zoneType, zoneIds in pairs(ZoneConstants.ZoneId) do
            for _, zoneId in pairs(zoneIds) do
                local zoneModel = ZoneUtil.getZoneModel(ZoneUtil.zone(zoneType, zoneId))

                local foundWaterInstances: { Instance } = {}
                for _, zoneWaterInstance in pairs(zoneWaterInstances) do
                    if zoneWaterInstance:IsDescendantOf(zoneModel) then
                        table.insert(foundWaterInstances, zoneWaterInstance)
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
                        (("Zone %s %s has more than one tagged ZoneWaterInstance (%s)"):format(zoneType, zoneId, foundList))
                    )
                end
            end
        end
    end

    return issues
end
