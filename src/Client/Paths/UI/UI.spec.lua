local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local DescendantLooper = require(ReplicatedStorage.Shared.DescendantLooper)

return function()
    local issues: { string } = {}

    -- ResetOnSpawn = false, Selectable+Active = false
    DescendantLooper.add(function(descendant)
        return (descendant:IsA("ScreenGui") or descendant:IsA("TextButton") or descendant:IsA("ImageButton")) and true or false
    end, function(instance: ScreenGui | TextButton | ImageButton)
        -- ScreenGui
        if instance:IsA("ScreenGui") then
            if instance.ResetOnSpawn then
                table.insert(issues, ("%s ResetOnSpawn is enabled - turn it off!"):format(instance:GetFullName()))
            end
            return
        end

        -- Button
        if instance:IsA("TextButton") or instance:IsA("ImageButton") then
            if not instance.Selectable then
                table.insert(issues, ("%s Selectable=false, could cause XBOX issues"):format(instance:GetFullName()))
            end
            if not instance.Active then
                table.insert(issues, ("%s Active=false, could cause XBOX issues"):format(instance:GetFullName()))
            end
            return
        end
    end, { StarterGui }, true)

    return issues
end
