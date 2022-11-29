local MinigamePromptInteraction = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local InteractionController = require(Paths.Client.Interactions.InteractionController)
local Remotes = require(Paths.Shared.Remotes)

InteractionController.registerInteraction("MinigamePrompt", function(instance)
    local queueStation = instance.Parent
    local isMultiplayer = queueStation:GetAttribute("Multiplayer")

    Remotes.invokeServer("MinigamePlayRequested", queueStation:GetAttribute("Minigame"), isMultiplayer, instance.Parent)

    if isMultiplayer then
        local prompts = InteractionController.getAllPromptsOfType("MinigamePrompt")
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
