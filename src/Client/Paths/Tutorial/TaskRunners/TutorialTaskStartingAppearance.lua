local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local TutorialController = require(Paths.Client.Tutorial.TutorialController)
local TutorialConstants = require(Paths.Shared.Tutorial.TutorialConstants)

return function()
    UIUtil.waitForHudAndRoomZone():andThen(function()
        UIController.getStateMachine():Push(UIConstants.States.StartingAppearance)

        -- Wait to leave this state
        while UIController.getStateMachine():HasState(UIConstants.States.StartingAppearance) do
            task.wait()
        end

        -- Inform of completion; important this is done *after* SetStartingAppearance. Server only accepts this request if task is not yet completed
        TutorialController.taskCompleted(TutorialConstants.Tasks.StartingAppearance)
    end)
end
