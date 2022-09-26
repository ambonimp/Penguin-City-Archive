local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local MinigameController = require(Paths.Client.Minigames.MinigameController)

return function()
    MinigameController.stop()
end
