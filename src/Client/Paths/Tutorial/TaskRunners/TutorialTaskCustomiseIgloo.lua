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

local uiStateMachine = UIController.getStateMachine()

return function()
    TutorialController.prompt("Looking Good!")

    -- Ensure player is in their igloo
    local iglooZone = ZoneUtil.houseInteriorZone(Players.LocalPlayer)
    local isInIglooZone = ZoneUtil.zonesMatch(ZoneController.getCurrentZone(), iglooZone)
    if not isInIglooZone then
        local teleportAssume = ZoneController.teleportToRoomRequest(iglooZone)
        teleportAssume:Await() -- Yield for Server/Client replication lag
    end

    TutorialController.prompt("You are in your igloo. Let's customize it!")

    warn("TODO highlight edit button")

    -- Wait for user to enter editing
    while not (uiStateMachine:HasState(UIConstants.States.HouseEditor)) do
        task.wait()
    end

    -- Wait for user to exit editing
    while uiStateMachine:HasState(UIConstants.States.HouseEditor) do
        task.wait()
    end

    -- Task Completed
    TutorialController.taskCompleted(TutorialConstants.Tasks.CustomiseIgloo)
end
