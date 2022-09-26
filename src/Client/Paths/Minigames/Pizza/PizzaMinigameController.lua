local PizzaMinigameController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local Output = require(Paths.Shared.Output)

function PizzaMinigameController.startMinigame()
    Output.doDebug(MinigameConstants.DoDebug, "startMinigame")
end

function PizzaMinigameController.stopMinigame()
    Output.doDebug(MinigameConstants.DoDebug, "stopMinigame")
end

return PizzaMinigameController
