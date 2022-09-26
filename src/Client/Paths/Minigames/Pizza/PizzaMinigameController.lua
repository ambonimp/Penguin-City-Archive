local PizzaMinigameController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local DebugUtil = require(Paths.Shared.Utils.DebugUtil)

function PizzaMinigameController.startMinigame()
    DebugUtil.debug(MinigameConstants.DoDebug, "PizzaMinigameController.startMinigame")
end

function PizzaMinigameController.stopMinigame()
    DebugUtil.debug(MinigameConstants.DoDebug, "PizzaMinigameController.stopMinigame")
end

return PizzaMinigameController
