local IceCreamExtravaganzaController = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Janitor = require(Paths.Packages.janitor)
local Remotes = require(Paths.Shared.Remotes)
local Images = require(Paths.Shared.Images.Images)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local SharedMinigameScreen = require(Paths.Client.UI.Screens.Minigames.SharedMinigameScreen)
local IceCreamExtravaganzaConstants = require(Paths.Shared.Minigames.IceCreamExtravaganza.IceCreamExtravaganzaConstants)
local CollectableController = require(Paths.Client.Minigames.IceCreamExtravaganza.IceCreamExtravaganzaCollectables)
local Confetti = require(Paths.Client.UI.Screens.SpecialEffects.Confetti)
local CameraController = require(Paths.Client.Minigames.IceCreamExtravaganza.IceCreamExtravaganzaCamera)

local MINIGAME_NAME = "IceCreamExtravaganza"

local AWARD_SEQUENCE_DELAY = 1
local RESTART_DELAY = 0.2

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local player = Players.LocalPlayer

local coreJanitor = Janitor.new()
local minigameJanitor = MinigameController.getMinigameJanitor()
minigameJanitor:Add(coreJanitor, "Cleanup")

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function unanchorCharacter()
    player.Character.Humanoid.WalkSpeed = IceCreamExtravaganzaConstants.WalkSpeed
end

local function anchorCharacter()
    player.Character.Humanoid.WalkSpeed = 0
end

-------------------------------------------------------------------------------
-- State handler
-------------------------------------------------------------------------------
MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.Nothing, function()
    SharedMinigameScreen.openStartMenu()
    minigameJanitor:Add(CameraController.setup())

    -- Disable walking
    anchorCharacter()

    -- Disable jumping
    local humanoid: Humanoid = player.Character.Humanoid
    minigameJanitor:Add(UserInputService.JumpRequest:Connect(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    end))

    MinigameController.playMusic("Intermission")
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
    coreJanitor:Add(CollectableController.setup())

    MinigameController.startCountdownAsync(MinigameConstants.CoreCountdownLength, SharedMinigameScreen.coreCountdown)

    -- GOOO!
    unanchorCharacter()
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.Core, function()
    MinigameController.stopMusic("Intermission")
    MinigameController.playMusic("Core")

    SharedMinigameScreen.setStatusText("Collect scoops!")
    MinigameController.startCountdownAsync(IceCreamExtravaganzaConstants.SessionConfig.CoreLength, SharedMinigameScreen.setStatusCounter)
end, function()
    SharedMinigameScreen.hideStatus()
    coreJanitor:Cleanup()
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.AwardShow, function(data)
    Confetti.play()

    MinigameController.stopMusic("Core")
    MinigameController.playMusic("Intermission")

    task.wait(AWARD_SEQUENCE_DELAY)

    anchorCharacter()

    local scores: MinigameConstants.SortedScores = data.Scores
    local isMultiplayer = MinigameController.isMultiplayer()

    if isMultiplayer then
        SharedMinigameScreen.openStandings(scores)
    end

    local placement = MinigameController.getOwnPlacement(scores)
    SharedMinigameScreen.openResults({
        if isMultiplayer then { Title = "Placement", Value = placement } else nil,
        { Title = "Scoops", Value = MinigameController.getOwnScore(scores) },
        {
            Title = "Total Coins",
            Icon = Images.Coins.Coin,
            Value = IceCreamExtravaganzaConstants.SessionConfig.Reward(placement),
        },
    })

    if not isMultiplayer then
        task.wait(RESTART_DELAY)
        Remotes.fireServer("MinigameRestarted")
        SharedMinigameScreen.openStartMenu()
    end
end)

return IceCreamExtravaganzaController
