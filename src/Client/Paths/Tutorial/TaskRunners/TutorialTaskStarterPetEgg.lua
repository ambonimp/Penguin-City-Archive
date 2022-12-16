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
local UIActions = require(Paths.Client.UI.UIActions)
local HUDScreen = require(Paths.Client.UI.Screens.HUD.HUDScreen)
local Maid = require(Paths.Packages.maid)

local uiStateMachine = UIController.getStateMachine()

return function(taskMaid: typeof(Maid.new()))
    TutorialController.prompt("You are all set! Here is a Pet Egg to get you started..")

    TutorialController.giveStarterPetEgg()

    warn("TODO tween pet egg into inventory button on hud")

    TutorialController.prompt(("You can hatch your egg in %d minutes!"):format(TutorialConstants.StarterEgg.HatchTimeMinutes))

    -- Task Completed
    TutorialController.taskCompleted(TutorialConstants.Tasks.StarterPetEgg)
end
