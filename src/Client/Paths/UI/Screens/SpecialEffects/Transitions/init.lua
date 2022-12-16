local Transitions = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local BlinkTransition = require(Paths.Client.UI.Screens.SpecialEffects.Transitions.BlinkTransition)

export type BlinkOptions = BlinkTransition.Options

Transitions.openBlink = BlinkTransition.open
Transitions.closeBlink = BlinkTransition.close
Transitions.blink = BlinkTransition.play

return Transitions
