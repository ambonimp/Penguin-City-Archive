local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local SinglePlayerMinigameController = require(Paths.Client.Minigames.SinglePlayerMinigameController)

return function(minigame: string)
    SinglePlayerMinigameController.play(minigame)
end
