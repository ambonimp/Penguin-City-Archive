local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local TutorialController = require(Paths.Client.Tutorial.TutorialController)
local ZoneController = require(Paths.Client.Zones.ZoneController)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local HUDScreen = require(Paths.Client.UI.Screens.HUD.HUDScreen)
local UIActions = require(Paths.Client.UI.UIActions)
local Maid = require(Paths.Shared.Maid)
local Promise = require(Paths.Packages.promise)

local uiStateMachine = UIController.getStateMachine()
local iglooZone = ZoneUtil.houseInteriorZone(Players.LocalPlayer)

return function(taskMaid: Maid.Maid)
    local isTutorialSkipped = false
    return Promise.new(function(resolve, _reject, onCancel)
        onCancel(function()
            isTutorialSkipped = true
        end)
        resolve()
    end)
        :andThen(function()
            return Promise.new(function(resolve)
                -- Prompts
                TutorialController.prompt("In Penguin City, you have your own igloo! Let's go there now..")

                resolve()
            end)
        end)
        :andThen(function()
            return Promise.new(function(resolve)
                -- Highlight Igloo Button
                local hideIglooFocalPoint = UIActions.focalPoint(HUDScreen.getIglooButton():GetButtonObject())
                taskMaid:GiveTask(hideIglooFocalPoint)

                -- Wait for user to go to their igloo
                while (isTutorialSkipped == false) and not (ZoneUtil.zonesMatch(ZoneController.getCurrentZone(), iglooZone)) do
                    task.wait()
                end
                hideIglooFocalPoint()

                resolve()
            end)
        end)
        :andThen(function()
            return Promise.new(function(resolve)
                -- Lock player to their igloo
                local unlock = ZoneController.lockToRoomZone(iglooZone, ZoneConstants.TravelMethod.Tutorial)
                taskMaid:GiveTask(unlock)

                TutorialController.prompt("This is your igloo... let's customize it!")

                resolve()
            end)
        end)
        :andThen(function()
            return Promise.new(function(resolve)
                -- Highlight Igloo Edit Button
                local hideEditFocalPoint = UIActions.focalPoint(HUDScreen.getIglooButton():GetButtonObject())
                taskMaid:GiveTask(hideEditFocalPoint)

                -- Wait for user to enter editing
                while (isTutorialSkipped == false) and not (uiStateMachine:HasState(UIConstants.States.HouseEditor)) do
                    task.wait()
                end
                hideEditFocalPoint()

                resolve()
            end)
        end)
        :andThen(function()
            return Promise.new(function(resolve)
                -- Wait for user to exit editing
                while uiStateMachine:HasState(UIConstants.States.HouseEditor) do
                    task.wait()
                end

                resolve()
            end)
        end)
end
