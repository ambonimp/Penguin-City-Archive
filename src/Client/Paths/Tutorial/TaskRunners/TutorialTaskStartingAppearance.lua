local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local TutorialController = require(Paths.Client.Tutorial.TutorialController)
local TutorialConstants = require(Paths.Shared.Tutorial.TutorialConstants)
local Maid = require(Paths.Shared.Maid)
local Promise = require(Paths.Packages.promise)

return function(_taskMaid: typeof(Maid.new()))
    local isTutorialSkipped = false
    return Promise.new(function(resolve, _reject, onCancel)
        onCancel(function()
            isTutorialSkipped = true
        end)
        resolve()
    end):andThen(function()
        return Promise.new(function(resolve)
            -- Put starting appearance on top of tutorial
            UIController.getStateMachine():Push(UIConstants.States.StartingAppearance)

            -- Wait to leave this state
            while (isTutorialSkipped == false) and UIController.getStateMachine():HasState(UIConstants.States.StartingAppearance) do
                task.wait()
            end

            resolve()
        end)
    end)
end
