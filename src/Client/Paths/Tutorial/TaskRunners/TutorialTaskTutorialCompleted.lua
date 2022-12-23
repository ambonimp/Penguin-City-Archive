local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TutorialController = require(Paths.Client.Tutorial.TutorialController)
local UIActions = require(Paths.Client.UI.UIActions)
local HUDScreen = require(Paths.Client.UI.Screens.HUD.HUDScreen)
local Maid = require(Paths.Shared.Maid)
local Promise = require(Paths.Packages.promise)
local Confetti = require(Paths.Client.UI.Screens.SpecialEffects.Confetti)

local PAUSE_TIME = 3

return function(taskMaid: Maid.Maid)
    local _isTutorialSkipped = false
    return Promise.new(function(resolve, _reject, onCancel)
        onCancel(function()
            _isTutorialSkipped = true
        end)
        resolve()
    end)
        :andThen(function()
            return Promise.new(function(resolve)
                TutorialController.prompt("Congratulations! You completed the tutorial.")

                Confetti.play()

                resolve()
            end)
        end)
        :andThen(function()
            return Promise.new(function(resolve)
                task.wait(PAUSE_TIME)

                resolve()
            end)
        end)
        :andThen(function()
            return Promise.new(function(resolve)
                TutorialController.prompt("Check out the Stamp Book to see all the things you can achieve!")

                TutorialController.prompt("Have fun and welcome to Penguin City :)")

                local hideStampBookFocalPoint = UIActions.focalPoint(HUDScreen.getStampBookButton():GetButtonObject())
                taskMaid:GiveTask(hideStampBookFocalPoint)

                task.wait(PAUSE_TIME)

                resolve()
            end)
        end)
end
