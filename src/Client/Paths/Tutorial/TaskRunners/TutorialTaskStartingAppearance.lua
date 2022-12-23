local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Shared.Maid)
local Promise = require(Paths.Packages.promise)

return function(_taskMaid: Maid.Maid)
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
