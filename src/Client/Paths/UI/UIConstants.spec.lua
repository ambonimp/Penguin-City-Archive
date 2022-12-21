local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TestUtil = require(Paths.Shared.Utils.TestUtil)
local UIConstants = require(Paths.Client.UI.UIConstants)

return function()
    local issues: { string } = {}

    -- States enum
    TestUtil.enum(UIConstants.States, issues)

    return issues
end
