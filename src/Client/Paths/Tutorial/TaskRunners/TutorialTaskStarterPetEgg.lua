local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local TutorialController = require(Paths.Client.Tutorial.TutorialController)
local ZoneController = require(Paths.Client.Zones.ZoneController)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local TutorialConstants = require(Paths.Shared.Tutorial.TutorialConstants)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)

local uiStateMachine = UIController.getStateMachine()

return function()
    TutorialController.prompt("You are all set! Here is a pet egg to get you started")

    TutorialController.giveStarterPetEgg()

    warn("TODO tween pet egg into inventory button on hud")

    TutorialController.prompt("You can hatch your first pet egg in 10 minutes!")

    -- Task Completed
    TutorialController.taskCompleted(TutorialConstants.Tasks.StarterPetEgg)
end
