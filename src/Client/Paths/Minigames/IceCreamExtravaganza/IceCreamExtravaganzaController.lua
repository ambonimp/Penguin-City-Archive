local IceCreamExtravaganzaController = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Janitor = require(Paths.Packages.janitor)
local Remotes = require(Paths.Shared.Remotes)
local Images = require(Paths.Shared.Images.Images)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local MinigameUtil = require(Paths.Shared.Minigames.MinigameUtil)
local SharedMinigameScreen = require(Paths.Client.UI.Screens.Minigames.SharedMinigameScreen)
local IceCreamExtravaganzaConstants = require(Paths.Shared.Minigames.IceCreamExtravaganza.IceCreamExtravaganzaConstants)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)

local MINIGAME_NAME = "IceCreamExtravaganza"
local INACTIVE_STARTING_LINE_TRANSPARENCY = 0.2

local AWARD_SEQUENCE_DELAY = 1
local RESTART_DELAY = 0.2

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local player = Players.LocalPlayer

local raceJanitor = Janitor.new()
local minigameJanitor = MinigameController.getMinigameJanitor()
minigameJanitor:Add(raceJanitor, "Cleanup")

-------------------------------------------------------------------------------
-- State handler
-------------------------------------------------------------------------------
MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.Nothing, function()
    SharedMinigameScreen.openStartMenu()
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.WaitingForPlayers, function()
    if MinigameController.isMultiplayer() then
        SharedMinigameScreen.setStatusText("Waiting for more players")
    end
end, function()
    SharedMinigameScreen.hideStatus()
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.Intermission, function()
    if MinigameController.isMultiplayer() then
        SharedMinigameScreen.openStartMenu()

        SharedMinigameScreen.setStatusText("Intermission")
        MinigameController.startCountdownAsync(
            IceCreamExtravaganzaConstants.SessionConfig.IntermissionLength,
            SharedMinigameScreen.setStatusCounter
        )
    end
end, function()
    SharedMinigameScreen.closeStartMenu()
    SharedMinigameScreen.hideStatus()
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.CoreCountdown, function()
    MinigameController.startCountdownAsync(4, SharedMinigameScreen.coreCountdown)
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.Core, function()
    SharedMinigameScreen.setStatusText("Collect scoops!")
    MinigameController.startCountdownAsync(IceCreamExtravaganzaConstants.SessionConfig.CoreLength, SharedMinigameScreen.setStatusCounter)
end, function()
    SharedMinigameScreen.hideStatus()
    raceJanitor:Cleanup()
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.AwardShow, function(data) end)

return IceCreamExtravaganzaController
