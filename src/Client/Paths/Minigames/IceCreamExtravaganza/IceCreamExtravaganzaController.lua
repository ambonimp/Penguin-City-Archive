local IceCreamExtravaganzaController = {}

local Players = game:GetService("Players")
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
local CollectableController = require(Paths.Client.Minigames.IceCreamExtravaganza.IceCreamExtravaganzaCollectables)
local ZoneController = require(Paths.Client.ZoneController)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)

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
-- State handler
-------------------------------------------------------------------------------
MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.Nothing, function()
    SharedMinigameScreen.openStartMenu()

    minigameJanitor:Add(task.spawn(function()
        -- Temporarily disable movement
        if ZoneController.getCurrentZone().ZoneType ~= ZoneConstants.ZoneType.Minigame then
            ZoneController.ZoneChanged:Wait()
        end
        CharacterUtil.anchor(player.Character)
    end))

    -- Disable jumping
    local humanoid: Humanoid = player.Character.Humanoid
    minigameJanitor:Add(UserInputService.JumpRequest:Connect(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    end))
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
    CharacterUtil.unanchor(player.Character)
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.Core, function()
    SharedMinigameScreen.setStatusText("Collect scoops!")
    MinigameController.startCountdownAsync(IceCreamExtravaganzaConstants.SessionConfig.CoreLength, SharedMinigameScreen.setStatusCounter)
end, function()
    SharedMinigameScreen.hideStatus()
    coreJanitor:Cleanup()
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.AwardShow, function(data)
    task.wait(AWARD_SEQUENCE_DELAY)
    CharacterUtil.anchor(player.Character)

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
