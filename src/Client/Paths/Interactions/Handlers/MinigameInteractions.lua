local MinigamePromptInteraction = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local InteractionController = require(Paths.Client.Interactions.InteractionController)
local Remotes = require(Paths.Shared.Remotes)
local Maid = require(Paths.Shared.Maid)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local BlinkTransition = require(Paths.Client.UI.Screens.SpecialEffects.Transitions.BlinkTransition)
local InteractionUtil = require(Paths.Shared.Utils.InteractionUtil)
local MinigameController = require(Paths.Client.Minigames.MinigameController)

local BLINK_OPTIONS: BlinkTransition.Options = {
    DoShowVoldexLoading = true,
    Scope = "Minigames",
}

local uiStateMachine = UIController.getStateMachine()

InteractionController.registerInteraction("MinigamePrompt", function(instance)
    local minigamePromptData = InteractionUtil.getMinigamePromptDataFromInteractionInstance(instance)
    local prompts = InteractionController.getAllProximityPromptsOfType("MinigamePrompt")
    for _, prompt in pairs(prompts) do
        prompt.Enabled = false
    end

    local maid = Maid.new()
    maid:GiveTask(function()
        for _, prompt in pairs(prompts) do
            prompt.Enabled = true
        end
    end)

    if minigamePromptData.IsMultiplayer then
        maid:GiveTask(Remotes.bindEventTemp("MinigameQueueExited", function()
            maid:Destroy()
        end))
    else
        -- Mask latency
        BlinkTransition.open(BLINK_OPTIONS)

        --[[
        task.wait(0.2)
        MinigameQueueScreen.open( minigameName, false) *]]
    end

    maid:GiveTask(uiStateMachine:RegisterStateCallbacks(UIConstants.States.Minigame, function()
        maid:Destroy()
    end))

    MinigameController.playRequest(minigamePromptData.Minigame, minigamePromptData.IsMultiplayer, instance.Parent)
end, "Play Minigame")

return MinigamePromptInteraction
