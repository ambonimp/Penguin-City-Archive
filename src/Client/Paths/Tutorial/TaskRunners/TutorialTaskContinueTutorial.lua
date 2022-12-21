local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local TutorialController = require(Paths.Client.Tutorial.TutorialController)
local TutorialConstants = require(Paths.Shared.Tutorial.TutorialConstants)
local Maid = require(Paths.Shared.Maid)
local Promise = require(Paths.Packages.promise)
local UIActions = require(Paths.Client.UI.UIActions)

return function(_taskMaid: typeof(Maid.new()))
    local _isTutorialSkipped = false
    return Promise.new(function(resolve, _reject, onCancel)
        onCancel(function()
            _isTutorialSkipped = true
        end)
        resolve()
    end):andThen(function()
        return Promise.new(function(resolve)
            -- Prompt asking to continue or not
            UIActions.prompt("Tutorial", "Would you like to continue with the tutorial? (Recommended)", nil, {
                Text = "Skip",
                Callback = function()
                    TutorialController.skipTutorial()
                    resolve()
                end,
            }, {
                Text = "Continue",
                Callback = resolve,
            })
        end)
    end)
end