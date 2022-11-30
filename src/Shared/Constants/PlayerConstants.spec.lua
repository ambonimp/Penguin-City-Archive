local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerConstants = require(ReplicatedStorage.Shared.Constants.PlayerConstants)

return function()
    local issues: { string } = {}

    -- AestheticRoleDetails keys must match name
    for key, aestheticRoleDetails in pairs(PlayerConstants.AestheticRoleDetails) do
        if key ~= aestheticRoleDetails.Name then
            table.insert(issues, ("AestheticRoleDetail %q key does not match name"):format(key))
        end
    end

    return issues
end
