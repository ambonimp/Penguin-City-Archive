local MinigamePromptInteraction = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local InteractionController = require(Paths.Client.Interactions.InteractionController)
local Remotes = require(Paths.Shared.Remotes)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local InteractionUtil = require(Paths.Shared.Utils.InteractionUtil)

InteractionController.registerInteraction("MinigamePrompt", function(instance)
    local minigamePromptData = InteractionUtil.getMinigamePromptDataFromInteractionInstance(instance)

    MinigameController.playRequest(minigamePromptData.Minigame, minigamePromptData.IsMultiplayer, instance.Parent)

    if minigamePromptData.IsMultiplayer then
        local prompts = InteractionController.getAllProximityPromptsOfType("MinigamePrompt")
        for _, prompt in pairs(prompts) do
            prompt.Enabled = false
        end

        local disconnect
        disconnect = Remotes.bindEventTemp("MinigameQueueExited", function()
            disconnect()
            for _, prompt in pairs(prompts) do
                prompt.Enabled = true
            end
        end)
    end
end, "Play Minigame")

return MinigamePromptInteraction
