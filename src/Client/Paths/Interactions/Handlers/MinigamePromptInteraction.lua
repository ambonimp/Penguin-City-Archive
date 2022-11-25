local MinigamePromptInteraction = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local InteractionController = require(Paths.Client.Interactions.InteractionController)
local Remotes = require(Paths.Shared.Remotes)

local COOLDOWN = 1
local debounce: true?

InteractionController.registerInteraction("MinigamePrompt", function(instance)
    if not debounce then
        debounce = true

        Remotes.invokeServer("MinigamePlayRequested", instance:GetAttribute("Minigame"), instance:GetAttribute("Multiplayer"))

        task.wait(COOLDOWN)
        debounce = nil
    end
end, "Play Minigame")

return MinigamePromptInteraction
