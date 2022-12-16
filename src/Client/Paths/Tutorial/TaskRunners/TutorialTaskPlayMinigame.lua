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
local Promise = require(Paths.Packages.promise)

local BOARDWALK_FOCAL_POINT_POSITION = UDim2.fromScale(0.51, 0.814)

local boardwalkZone = ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, ZoneConstants.ZoneType.Room.Boardwalk)
local pizzaPlaceZone = ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, ZoneConstants.ZoneType.Room.PizzaPlace)

return function(taskMaid: typeof(Maid.new()))
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
                        task.wait(1) --!! temp
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
                -- Wait for user to get to the boardwalk
                while (isTutorialSkipped == false) and not (ZoneUtil.zonesMatch(ZoneController.getCurrentZone(), pizzaPlaceZone)) do
                    task.wait()
                end

                -- Lock them to the boardwalk
                local unlock = ZoneController.lockToRoomZone(boardwalkZone)
                taskMaid:GiveTask(unlock())

                resolve()
            end)
        end)
        :andThen(function()
            return Promise.new(function(resolve)
                -- Wait for user to be inside the pizza place
                while (isTutorialSkipped == false) and not (ZoneUtil.zonesMatch(ZoneController.getCurrentZone(), pizzaPlaceZone)) do
                    task.wait()
                end

                -- Lock them to pizza place
                local unlock = ZoneController.lockToRoomZone(pizzaPlaceZone)
                taskMaid:GiveTask(unlock)

                resolve()
            end)
        end)
        :andThen(function()
            return Promise.new(function(resolve)
                -- Start minigame request for user
                MinigameController.playRequest(MinigameConstants.Minigames.PizzaFiasco, false)

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
