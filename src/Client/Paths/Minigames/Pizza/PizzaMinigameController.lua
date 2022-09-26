local PizzaMinigameController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local Logger = require(Paths.Shared.Logger)

function PizzaMinigameController.startMinigame()
    Logger.doDebug(MinigameConstants.DoDebug, "PizzaMinigameController.startMinigame")
end

function PizzaMinigameController.stopMinigame()
    Logger.doDebug(MinigameConstants.DoDebug, "PizzaMinigameController.stopMinigame")
end

return PizzaMinigameController
