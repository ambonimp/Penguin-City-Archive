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
local InteractionUtil = require(Paths.Shared.Utils.InteractionUtil)
local MinigameController = require(Paths.Client.Minigames.MinigameController)

local uiStateMachine = UIController.getStateMachine()

InteractionController.registerInteraction("MinigamePrompt", function(instance)
    local minigamePromptData = InteractionUtil.getMinigamePromptDataFromInteractionInstance(instance)
    local prompts = InteractionController.getAllProximityPromptsOfType("MinigamePrompt")
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

    if minigamePromptData.IsMultiplayer then
        disconnect = Remotes.bindEventTemp("MinigameQueueExited", reenablePrompts)
    else
        -- Mask latency
        BlinkTransition.open()
        reenablePrompts()

        --[[
        task.wait(0.2)
        MinigameQueueScreen.open( minigameName, false) *]]
    end

    if uiStateMachine:GetState() ~= UIConstants.States then
        disconnect = uiStateMachine:RegisterStateCallbacks(UIConstants.States.Minigame, reenablePrompts)
    end

    MinigameController.playRequest(minigamePromptData.Minigame, minigamePromptData.IsMultiplayer, instance.Parent)
end, "Play Minigame")

return MinigamePromptInteraction
