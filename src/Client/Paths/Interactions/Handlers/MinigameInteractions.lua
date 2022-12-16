local MinigamePromptInteraction = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local InteractionController = require(Paths.Client.Interactions.InteractionController)
local Remotes = require(Paths.Shared.Remotes)
local MinigameQueueScreen = require(Paths.Client.UI.Screens.Minigames.MinigameQueueScreen)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local Signal = require(Paths.Shared.Signal)
local BlinkTransition = require(Paths.Client.UI.Screens.SpecialEffects.Transitions.BlinkTransition)

local uiStateMachine = UIController.getStateMachine()

InteractionController.registerInteraction("MinigamePrompt", function(instance)
    local queueStation = instance.Parent
    local isMultiplayer = queueStation:GetAttribute("Multiplayer")
    local minigameName = queueStation:GetAttribute("Minigame")

    local prompts = InteractionController.getAllPromptsOfType("MinigamePrompt")
    for _, prompt in pairs(prompts) do
        prompt.Enabled = false
    end

    local disconnect: Signal.Connection | () -> ()
    local function reenablePrompts()
        if disconnect then
            if typeof(disconnect) == "function" then
                disconnect()
            else
                disconnect:Disconnect()
            end
        end
        for _, prompt in pairs(prompts) do
            prompt.Enabled = true
        end
    end

    if isMultiplayer then
        disconnect = Remotes.bindEventTemp("MinigameQueueExited", reenablePrompts)
    else
        -- Mask latency
        BlinkTransition.open()
        reenablePrompts()

        --[[
        task.wait(0.2)
        MinigameQueueScreen.open( minigameName, false) *]]

        if uiStateMachine:GetState() ~= UIConstants.States then
            disconnect = uiStateMachine:RegisterStateCallbacks(UIConstants.States.Minigame, reenablePrompts)
        end
    end

    Remotes.invokeServer("MinigamePlayRequested", minigameName, isMultiplayer, instance.Parent)
end, "Play Minigame")

return MinigamePromptInteraction
