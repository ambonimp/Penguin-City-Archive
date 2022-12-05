local MinigamePromptInteraction = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local InteractionController = require(Paths.Client.Interactions.InteractionController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)

local uiStateMachine = UIController.getStateMachine()

InteractionController.registerInteraction("CharacterEditorPrompt", function(instance)
    if uiStateMachine:GetState() ~= UIConstants.States.CharacterEditor then
        local tab = instance:GetAttribute("Tab")
        tab = if tab and tab == "" then nil else tab
        uiStateMachine:Push(UIConstants.States.CharacterEditor, { Tab = tab })
    end
end)

return MinigamePromptInteraction
