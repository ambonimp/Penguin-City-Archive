local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)

return function()
    local issues: { string } = {}

    -- Verify Structure for tagged DiscoBalls
    local discoBalls: { Model } = CollectionService:GetTagged(ZoneConstants.Cosmetics.Tags.DiscoBall)
    for _, discoBall in pairs(discoBalls) do
        -- Must be a Model
        if not discoBall:IsA("Model") then
            table.insert(issues, ("Tagged DiscoBall %s is not a Model!"):format(discoBall:GetFullName()))
        end

        -- ColorParts must be BaseParts
        local colorPartCount = 0
        for _, descendant in pairs(discoBall:GetDescendants()) do
            if descendant.Name == ZoneConstants.Cosmetics.Disco.ColorPartName then
                if descendant:IsA("BasePart") then
                    colorPartCount += 1
                else
                    table.insert(issues, ("Tagged DiscoBall has a bad ColorPart %s (not a BasePart)"):format(descendant:GetFullName()))
                end
            end
        end

        -- Must have *some* ColorParts!
        if colorPartCount == 0 then
            table.insert(issues, ("Tagged DiscoBall %s has no ColorParts!"):format(discoBall:GetFullName()))
        end
    end

    return issues
end
