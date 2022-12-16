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
local HUDScreen = require(Paths.Client.UI.Screens.HUD.HUDScreen)
local UIActions = require(Paths.Client.UI.UIActions)
local Maid = require(Paths.Packages.maid)

local uiStateMachine = UIController.getStateMachine()

return function(_taskMaid: typeof(Maid.new()))
    TutorialController.prompt("Looking Good!")

    TutorialController.prompt("In Penguin City, you have your own igloo! Let's go there now..")

    -- Highlight Igloo Button
    local hideIglooFocalPoint = UIActions.focalPoint(HUDScreen.getIglooButton():GetButtonObject())

    -- Wait for user to go to their igloo
    local iglooZone = ZoneUtil.houseInteriorZone(Players.LocalPlayer)
    while not (ZoneUtil.zonesMatch(ZoneController.getCurrentZone(), iglooZone)) do
        task.wait()
    end
    hideIglooFocalPoint()

    -- Lock player to their igloo
    ZoneController.lockToRoomZone(iglooZone)

    TutorialController.prompt("This is your igloo... let's customize it!")

    -- Highlight Igloo Edit Button
    local hideFocalPoint = UIActions.focalPoint(HUDScreen.getIglooButton():GetButtonObject())

    -- Wait for user to enter editing
    while not (uiStateMachine:HasState(UIConstants.States.HouseEditor)) do
        task.wait()
    end
    hideFocalPoint()

    -- Wait for user to exit editing
    while uiStateMachine:HasState(UIConstants.States.HouseEditor) do
        task.wait()
    end

    -- Unlock player
    ZoneController.lockToRoomZone()

    -- Task Completed
    TutorialController.taskCompleted(TutorialConstants.Tasks.CustomiseIgloo)
end
