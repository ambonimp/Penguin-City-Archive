local CollectionService = game:GetService("CollectionService")

return function()
    local issues: { string } = {}

    -- Verify Structure for tagged AnimatedFlags
    local animatedFlags: { BasePart } = CollectionService:GetTagged("AnimatedFlag")
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
