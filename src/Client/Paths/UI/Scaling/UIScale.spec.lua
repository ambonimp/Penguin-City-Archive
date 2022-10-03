local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)

return function()
    local issues: { string } = {}

    for _, descendant in Paths.UI:GetDescendants() do
        if descendant:IsA("UIScale") then
            local parent = descendant.Parent
            if not parent.Parent:IsA("ScreenGui") then
                table.insert(
                    issues,
                    string.format("UIScales can only be applied to children of ScreenGuis, the one in %s is invalid", parent.Name)
                )
            end
        end
    end

    return issues
end
