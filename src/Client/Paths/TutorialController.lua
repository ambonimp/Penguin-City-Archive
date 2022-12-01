local TutorialController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local TutorialConstants = require(Paths.Shared.Tutorial.TutorialConstants)
local DataController = require(Paths.Client.DataController)
local TutorialUtil = require(Paths.Shared.Tutorial.TutorialUtil)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)

function TutorialController.Start()
    -- Tasks
    do
        -- StartingAppearance
        if not TutorialController.isTaskCompleted(TutorialConstants.Tasks.StartingAppearance) then
            UIUtil.waitForHudAndRoomZone():andThen(function()
                UIController.getStateMachine():Push(UIConstants.States.StartingAppearance)
            end)
        end
    end
end

-------------------------------------------------------------------------------
-- Querying
-------------------------------------------------------------------------------

function TutorialController.isTaskCompleted(task: string)
    return DataController.get(TutorialUtil.getTaskDataAddress(task)) and true or false
end

-------------------------------------------------------------------------------
-- Task Informers
-------------------------------------------------------------------------------

--[[
    Indexes refer to TutorialConstants.StartingAppearance tables
]]
function TutorialController.setStartingAppearance(colorIndex: number, outfitIndex: number)
    -- Apply appearance locally
    do
        local character = Players.LocalPlayer.Character
        if character then
            CharacterUtil.applyAppearance(character, TutorialUtil.buildAppearanceFromColorAndOutfitIndexes(colorIndex, outfitIndex))
        end
    end

    -- Inform Server
    Remotes.fireServer("SetStartingAppearance", colorIndex, outfitIndex)
end

return TutorialController
