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
    TutorialController.prompt("You can earn coins by playing minigames!")

    warn("TODO highlight map button")

    -- Wait for user to enter map
    while not (uiStateMachine:HasState(UIConstants.States.Map)) do
        task.wait()
    end

    warn("TODO highlight pizza fiasco")

    -- Wait for user to be inside the pizza place
    local pizzaPlaceZone = ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, ZoneConstants.ZoneType.Room.PizzaPlace)
    while not (ZoneUtil.zonesMatch(ZoneController.getCurrentZone(), pizzaPlaceZone)) do
        task.wait()
    end

    -- Start minigame request for user
    MinigameController.playRequest(MinigameConstants.Minigames.PizzaFiasco, false)

    -- Wait for user to start minigame
    while not (ZoneController.getCurrentZone().ZoneCategory == ZoneConstants.ZoneCategory.Minigame) do
        task.wait()
    end

    -- Wait for user to finish minigame
    while ZoneController.getCurrentZone().ZoneCategory == ZoneConstants.ZoneCategory.Minigame do
        task.wait()
    end

    -- Task Completed
    TutorialController.taskCompleted(TutorialConstants.Tasks.PlayMinigame)
end
