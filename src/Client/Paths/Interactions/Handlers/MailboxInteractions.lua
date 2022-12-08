local MailboxInteractions = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local InteractionController = require(Paths.Client.Interactions.InteractionController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)

local uiStateMachine = UIController.getStateMachine()

InteractionController.registerInteraction("MailboxSettings", function(instance, prompt)
    local state = uiStateMachine:GetState()
    if
        not (
            state == UIConstants.States.PlotSettings
            or state == UIConstants.States.HouseSelectionUI
            or state == UIConstants.States.PlotChanger
        )
    then
        uiStateMachine:Push(UIConstants.States.PlotSettings, { Instance = instance, Prompt = prompt, PlotAt = prompt.Parent.Parent })
    end
end)

return MailboxInteractions
