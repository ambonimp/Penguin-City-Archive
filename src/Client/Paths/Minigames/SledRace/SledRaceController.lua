local SledRaceController = {}

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
local DrivingController = require(Paths.Client.Minigames.SledRace.SledRaceDriving)
local CameraController = require(Paths.Client.Minigames.SledRace.SledRaceCamera)
local CollectableController = require(Paths.Client.Minigames.SledRace.SledRaceCollectables)
local ProgressLineController = require(Paths.Client.Minigames.SledRace.SledRaceProgressLine)
local SharedMinigameScreen = require(Paths.Client.UI.Screens.Minigames.SharedMinigameScreen)
local SledRaceConstants = require(Paths.Shared.Minigames.SledRace.SledRaceConstants)

local MINIGAME_NAME = "SledRace"
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
    minigameJanitor:Add(CameraController.setup())

    -- Disable movement
    local humanoid: Humanoid = player.Character.Humanoid
    minigameJanitor:Add(UserInputService.JumpRequest:Connect(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    end))
    minigameJanitor:Add(RunService.RenderStepped:Connect(function()
        humanoid:ChangeState(Enum.HumanoidStateType.Seated)
    end))

    MinigameController.playMusic("Intermission")
    SharedMinigameScreen.openStartMenu()
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.Intermission, function()
    if MinigameController.isMultiplayer() then
        SharedMinigameScreen.openStartMenu()

        SharedMinigameScreen.setStatusText("Intermission")
        MinigameController.startCountdownAsync(SledRaceConstants.SessionConfig.IntermissionLength, SharedMinigameScreen.setStatusCounter)
    end
end, function()
    SharedMinigameScreen.closeStartMenu()
    SharedMinigameScreen.hideStatus()
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.CoreCountdown, function()
    MinigameController.stopMusic("Intermission")

    raceJanitor:Add(CollectableController.setup())

    --[[
        Client tells itself when to give player control of driving
        This way people with worser ping have less of a disadvantage on start
    ]]
    MinigameController.startCountdownAsync(MinigameConstants.CoreCountdownLength, SharedMinigameScreen.coreCountdown)

    local startingLine = MinigameController.getMap().Course.Start.StartingLine.PrimaryPart
    startingLine.Transparency = 1
    raceJanitor:Add(function()
        startingLine.Transparency = INACTIVE_STARTING_LINE_TRANSPARENCY
    end)

    -- Goo
    raceJanitor:Add(DrivingController.setup())
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.Core, function()
    MinigameController.playMusic("Core")

    raceJanitor:Add(ProgressLineController.setup())
    SharedMinigameScreen.setStatusText("Race to the bottom")

    MinigameController.startCountdownAsync(SledRaceConstants.SessionConfig.CoreLength, SharedMinigameScreen.setStatusCounter)
end, function()
    SharedMinigameScreen.hideStatus()
    raceJanitor:Cleanup()
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.AwardShow, function(data)
    MinigameController.stopMusic("Core")
    MinigameController.playMusic("Intermission")

    local scores: MinigameConstants.SortedScores = data.Scores
    local isMultiplayer = MinigameController.isMultiplayer()

    task.wait(AWARD_SEQUENCE_DELAY)

    if isMultiplayer then
        SharedMinigameScreen.openStandings(scores)
    end

    local placement = MinigameController.getOwnPlacement(scores)
    local coinsCollected = CollectableController.getCoinsCollected()

    SharedMinigameScreen.openResults({
        if isMultiplayer then { Title = "Placement", Value = placement } else nil,
        {
            Title = "Time",
            Value = MinigameUtil.formatScore(MinigameController.getMinigame(), MinigameController.getOwnScore(scores)),
            Tag = MinigameController.isNewBest(scores) and "New Best",
        },
        { Title = "Coins Collected", Value = coinsCollected },
        { Title = "Total Coins", Icon = Images.Coins.Coin, Value = SledRaceConstants.SessionConfig.Reward(placement) + coinsCollected },
    })

    if isMultiplayer then
        Remotes.fireServer("MinigameExited")
    else
        task.wait(RESTART_DELAY)
        Remotes.fireServer("MinigameRestarted")
        SharedMinigameScreen.openStartMenu()
    end
end)

return SledRaceController
