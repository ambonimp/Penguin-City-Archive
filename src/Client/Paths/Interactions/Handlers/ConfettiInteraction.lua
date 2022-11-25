local ConfettiInteraction = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local InteractionController = require(Paths.Client.Interactions.InteractionController)
local Confetti = require(Paths.Client.UI.Screens.SpecialEffects.Confetti)

local COOLDOWN = 2

local debounce: true?

InteractionController.registerInteraction("Confetti", function(_, prompt)
    if not debounce then
        Confetti.play()

        prompt.Enabled = false
        task.wait(COOLDOWN)
        prompt.Enabled = true
    end
end, "Shoot Confetti")

return ConfettiInteraction
