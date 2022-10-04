local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)

return function()
    local issues: { string } = {}

    for _, descendant in Paths.UI:GetDescendants() do
        if descendant:IsA("UIScale") then
            local isDirectChildOfScreenGui = descendant.Parent and descendant.Parent:IsA("ScreenGui")
            if isDirectChildOfScreenGui then
                table.insert(
                    issues,
                    string.format("UIScales should not be direct children of ScreenGuis - put %s inside a frame!", descendant:GetFullName())
                )
            end
        end
    end

    return issues
end
