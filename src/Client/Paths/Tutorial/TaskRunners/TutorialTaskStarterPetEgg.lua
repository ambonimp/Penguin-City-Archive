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

local PAUSE_AFTER_EGG = 0.8

return function(_taskMaid: typeof(Maid.new()))
    local _isTutorialSkipped = false
    return Promise.new(function(resolve, _reject, onCancel)
        onCancel(function()
            _isTutorialSkipped = true
        end)
        resolve()
    end)
        :andThen(function()
            return Promise.new(function(resolve)
                TutorialController.prompt("You are all set! Here is a Pet Egg to get you started..")

                TutorialController.giveStarterPetEgg()

                resolve()
            end)
        end)
        :andThen(function()
            return Promise.new(function(resolve)
                TutorialController.tweenPetEggIntoInventory()
                task.wait(PAUSE_AFTER_EGG)

                resolve()
            end)
        end)
        :andThen(function()
            return Promise.new(function(resolve)
                TutorialController.prompt(("You can hatch your egg in %d minutes!"):format(TutorialConstants.StarterEgg.HatchTimeMinutes))

                resolve()
            end)
        end)
end
