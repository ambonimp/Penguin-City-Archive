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

local BOARDWALK_FOCAL_POINT_POSITION = UDim2.fromScale(0.51, 0.814)

local uiStateMachine = UIController.getStateMachine()
local boardwalkZone = ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, ZoneConstants.ZoneType.Room.Boardwalk)
local pizzaPlaceZone = ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, ZoneConstants.ZoneType.Room.PizzaPlace)

return function(taskMaid: typeof(Maid.new()))
    TutorialController.prompt("You can earn coins by playing minigames!")

    -------------------------------------------------------------------------------
    -- MAP FOCUS: Focus on the HUD map button
    -------------------------------------------------------------------------------

    local mapFocusMaid = Maid.new()
    local function mapFocus()
        print("map focus")
        mapFocusMaid:Cleanup()

        -- RETURN: In a good zone
        local currentZone = ZoneController.getCurrentZone()
        local isInGoodZone = ZoneUtil.zonesMatch(currentZone, boardwalkZone) or ZoneUtil.zonesMatch(currentZone, pizzaPlaceZone)
        if isInGoodZone then
            print(1)
            return
        end

        -- Focus on map
        print("focus on map")
        local hideMapFocalPoint = UIActions.focalPoint(HUDScreen.getMapButton():GetButtonObject())
        mapFocusMaid:GiveTask(hideMapFocalPoint)
    end
    taskMaid:GiveTask(mapFocusMaid)

    -- Focus on map now, whenever UI State changes and zone teleports
    mapFocus()
    taskMaid:GiveTask(UIController.getStateMachine():RegisterGlobalCallback(function(_fromState, toState)
        mapFocusMaid:Cleanup()

        if toState == UIConstants.States.HUD then
            mapFocus()
        end
    end))
    taskMaid:GiveTask(ZoneController.ZoneChanged:Connect(mapFocus))

    -------------------------------------------------------------------------------
    -- BOARDWALK FOCUS: Focus on the boardwalk section of the Map UI
    -------------------------------------------------------------------------------

    local boardwalkFocusMaid = Maid.new()
    local function boardwalkFocus()
        -- Focus
        local hideBoardwalkFocalPoint = UIActions.focalPoint(BOARDWALK_FOCAL_POINT_POSITION)
        boardwalkFocusMaid:GiveTask(hideBoardwalkFocalPoint)
    end
    taskMaid:GiveTask(boardwalkFocusMaid)

    -- Focus on boardwalk when we open up the map
    taskMaid:GiveTask(UIController.getStateMachine():RegisterGlobalCallback(function(_fromState, toState)
        boardwalkFocusMaid:Cleanup()

        if toState == UIConstants.States.Map then
            boardwalkFocus()
        end
    end))

    -------------------------------------------------------------------------------
    -- Logic Flow
    -------------------------------------------------------------------------------

    -- Wait for user to be inside the pizza place
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

    taskMaid:Destroy()
end
