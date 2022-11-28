local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)

return function()
    local issues: { string } = {}

    -- Verify Structure for tagged AnimatedFlags
    local animatedFlags: { BasePart } = CollectionService:GetTagged(ZoneConstants.Cosmetics.Tags.AnimatedFlag)
    for _, animatedFlag in pairs(animatedFlags) do
        -- Must be a BasePart
        if not animatedFlag:IsA("BasePart") then
            table.insert(issues, ("Tagged AnimatedFlag %s is not a BasePart!"):format(animatedFlag:GetFullName()))
        end

        -- Must have an attachment
        if not animatedFlag:FindFirstChildOfClass("Attachment") then
            table.insert(issues, ("Tagged AnimatedFlag %s has no child Attachment!"):format(animatedFlag:GetFullName()))
        end
    end

    return issues
end
