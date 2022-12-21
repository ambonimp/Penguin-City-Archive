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
local Maid = require(Paths.Shared.Maid)
local Promise = require(Paths.Packages.promise)
local NavigationArrow = require(Paths.Shared.NavigationArrow)
local InteractionController = require(Paths.Client.Interactions.InteractionController)
local InteractionUtil = require(Paths.Shared.Utils.InteractionUtil)

local BOARDWALK_FOCAL_POINT_POSITION = UDim2.fromScale(0.505, 0.82)

local boardwalkZone = ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, ZoneConstants.ZoneType.Room.Boardwalk)
local pizzaPlaceZone = ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, ZoneConstants.ZoneType.Room.PizzaPlace)

return function(taskMaid: typeof(Maid.new()))
    local navigationArrow = NavigationArrow.new()
    taskMaid:GiveTask(navigationArrow)

    local isTutorialSkipped = false
    return Promise.new(function(resolve, _reject, onCancel)
        onCancel(function()
            isTutorialSkipped = true
        end)
        resolve()
    end)
        :andThen(function()
            return Promise.new(function(resolve)
                TutorialController.prompt("You can earn coins by playing minigames!")

                resolve()
            end)
        end)
        :andThen(function()
            return Promise.new(function(resolve)
                -------------------------------------------------------------------------------
                -- MAP FOCUS: Focus on the HUD map button
                -------------------------------------------------------------------------------

                local mapFocusMaid = Maid.new()
                taskMaid:GiveTask(mapFocusMaid)

                local isMapFocused = false
                local function mapFocus(doFocus: boolean)
                    -- DON'T FOCUS: In a good zone
                    local currentZone = ZoneController.getCurrentZone()
                    local isInGoodZone = currentZone.ZoneCategory == ZoneConstants.ZoneCategory.Minigame
                        or ZoneUtil.zonesMatch(currentZone, boardwalkZone)
                        or ZoneUtil.zonesMatch(currentZone, pizzaPlaceZone)
                    if isInGoodZone then
                        doFocus = false
                    end

                    -- RETURN: No change!
                    if isMapFocused == doFocus then
                        return
                    end
                    isMapFocused = doFocus

                    if isMapFocused then
                        -- Focus on map
                        local hideMapFocalPoint = UIActions.focalPoint(HUDScreen.getMapButton():GetButtonObject())
                        mapFocusMaid:GiveTask(hideMapFocalPoint)
                    else
                        mapFocusMaid:Cleanup()
                    end
                end

                -- Map Focus Callbacks
                taskMaid:GiveTask(UIController.StateMaximized:Connect(function(state)
                    if state == UIConstants.States.HUD then
                        mapFocus(true)
                    end
                end))
                taskMaid:GiveTask(UIController.StateMinimized:Connect(function(state)
                    if state == UIConstants.States.HUD then
                        mapFocus(false)
                    end
                end))
                taskMaid:GiveTask(ZoneController.ZoneChanged:Connect(function()
                    mapFocus(UIController.isStateMaximized(UIConstants.States.HUD))
                end))
                mapFocus(UIController.isStateMaximized(UIConstants.States.HUD))

                resolve()
            end)
        end)
        :andThen(function()
            return Promise.new(function(resolve)
                -------------------------------------------------------------------------------
                -- BOARDWALK FOCUS: Focus on the boardwalk section of the Map UI
                -------------------------------------------------------------------------------

                local boardwalkFocusMaid = Maid.new()
                taskMaid:GiveTask(boardwalkFocusMaid)

                local isBoardwalkFocused = false
                local function boardwalkFocus(doFocus: boolean)
                    -- RETURN: No change!
                    if doFocus == isBoardwalkFocused then
                        return
                    end
                    isBoardwalkFocused = doFocus

                    if doFocus then
                        -- Focus
                        local hideBoardwalkFocalPoint = UIActions.focalPoint(BOARDWALK_FOCAL_POINT_POSITION)
                        boardwalkFocusMaid:GiveTask(hideBoardwalkFocalPoint)
                    else
                        boardwalkFocusMaid:Cleanup()
                    end
                end

                -- Boardwalk Focus Callbacks
                taskMaid:GiveTask(UIController.StateMaximized:Connect(function(state)
                    if state == UIConstants.States.Map then
                        boardwalkFocus(true)
                    end
                end))
                taskMaid:GiveTask(UIController.StateMinimized:Connect(function(state)
                    if state == UIConstants.States.Map then
                        boardwalkFocus(false)
                    end
                end))
                boardwalkFocus(UIController.isStateMaximized(UIConstants.States.Map))

                resolve()
            end)
        end)
        :andThen(function()
            return Promise.new(function(resolve)
                -------------------------------------------------------------------------------
                -- NAVIGATION ARROWS
                -------------------------------------------------------------------------------

                taskMaid:GiveTask(ZoneController.ZoneChanged:Connect(function(_fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone)
                    -- Clear arrow on teleport
                    navigationArrow:Clear()

                    -- Boardwalk -> PizzaPlace
                    if ZoneUtil.zonesMatch(toZone, boardwalkZone) then
                        -- WARN: Could not get teleporter
                        local pizzaPlaceTeleporter = ZoneUtil.getZoneInstances(boardwalkZone).RoomDepartures:FindFirstChild("PizzaPlace")
                        if not pizzaPlaceTeleporter then
                            warn("Could not find pizza place teleporter")
                            return
                        end

                        navigationArrow:GuidePlayer(Players.LocalPlayer, pizzaPlaceTeleporter)
                        return
                    end

                    -- PizzaPlace -> PizzaFiasco
                    if ZoneUtil.zonesMatch(toZone, pizzaPlaceZone) then
                        -- Get MinigameInteractions
                        local minigameInteractionInstances =
                            InteractionController.getAllInteractionInstancesOfType("MinigamePrompt", ZoneUtil.getZoneModel(pizzaPlaceZone))

                        -- Get PizzaFiasco MinigameInteraction
                        local pizzaFiascoInteractionInstance: Instance
                        for _, minigameInteractionInstance in pairs(minigameInteractionInstances) do
                            local minigamePromptData =
                                InteractionUtil.getMinigamePromptDataFromInteractionInstance(minigameInteractionInstance)
                            if minigamePromptData.Minigame == MinigameConstants.Minigames.PizzaFiasco then
                                pizzaFiascoInteractionInstance = minigameInteractionInstance
                                break
                            end
                        end
                        -- WARN: Could not find minigame interaction
                        if not pizzaFiascoInteractionInstance then
                            warn("Could not find PizzaFiasco MinigamePrompt")
                            return
                        end

                        navigationArrow:GuidePlayer(Players.LocalPlayer, pizzaFiascoInteractionInstance)
                        return
                    end
                end))

                resolve()
            end)
        end)
        :andThen(function()
            return Promise.new(function(resolve)
                -- Wait for user to start minigame
                while
                    (isTutorialSkipped == false)
                    and not (ZoneController.getCurrentZone().ZoneCategory == ZoneConstants.ZoneCategory.Minigame)
                do
                    task.wait()
                end

                resolve()
            end)
        end)
        :andThen(function()
            return Promise.new(function(resolve)
                -- Wait for user to finish minigame
                while
                    (isTutorialSkipped == false) and ZoneController.getCurrentZone().ZoneCategory == ZoneConstants.ZoneCategory.Minigame
                do
                    task.wait()
                end

                resolve()
            end)
        end)
end
