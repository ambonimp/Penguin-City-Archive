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
local Confetti = require(Paths.Client.UI.Screens.SpecialEffects.Confetti)

local PAUSE_TIME = 3

return function(taskMaid: typeof(Maid.new()))
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
