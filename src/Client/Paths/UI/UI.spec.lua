local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local DescendantLooper = require(ReplicatedStorage.Shared.DescendantLooper)

return function()
    local issues: { string } = {}

    -- ResetOnSpawn = false
    DescendantLooper.add(function(descendant)
        return descendant:IsA("ScreenGui") and true or false
    end, function(screenGui: ScreenGui)
        if screenGui.ResetOnSpawn then
            table.insert(issues, ("%s ResetOnSpawn is enabled - turn it off!"):format(screenGui:GetFullName()))
        end
    end, { StarterGui }, true)

    return issues
end
