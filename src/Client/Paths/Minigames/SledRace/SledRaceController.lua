local SledRaceController = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)
local Remotes = require(Paths.Shared.Remotes)
local Images = require(Paths.Shared.Images.Images)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local MinigameUtil = require(Paths.Shared.Minigames.MinigameUtil)
local DrivingController = require(Paths.Client.Minigames.SledRace.SledRaceDriving)
local CameraController = require(Paths.Client.Minigames.SledRace.SledRaceCamera)
local CollectableController = require(Paths.Client.Minigames.SledRace.SledRaceCollectables)
local ProgressLineController = require(Paths.Client.Minigames.SledRace.SledRaceProgressLine)
local MinigameScreenUtil = require(Paths.Client.UI.Screens.Minigames.MinigameScreenUtil)

local MINIGAME_NAME = "SledRace"
local INACTIVE_STARTING_LINE_TRANSPARENCY = 0.2

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local player = Players.LocalPlayer

local raceMaid = Maid.new()
local minigameMaid = MinigameController.getMinigameMaid()
minigameMaid:GiveTask(raceMaid)

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.Nothing, function()
    minigameMaid:GiveTask(CameraController.setup())

    -- Disable movement
    local humanoid: Humanoid = player.Character.Humanoid
    minigameMaid:GiveTask(UserInputService.JumpRequest:Connect(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    end))
    minigameMaid:GiveTask(RunService.RenderStepped:Connect(function()
        humanoid:ChangeState(Enum.HumanoidStateType.Seated)
    end))

    MinigameScreenUtil.openMenu()
    minigameMaid:GiveTask(function()
        MinigameScreenUtil.closeMenu()
    end)
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.CoreCountdown, function()
    raceMaid:GiveTask(CollectableController.setup())
    raceMaid:GiveTask(ProgressLineController.setup())

    --[[
        Client tells itself when to give player control of driving
        This way people with worser ping have less of a disadvantage on start
    ]]
    MinigameController.startCountdownAsync(4, MinigameScreenUtil.coreCountdown)

    local startingLine = MinigameController.getMap().StartingLine.PrimaryPart
    startingLine.Transparency = 1
    raceMaid:GiveTask(function()
        startingLine.Transparency = INACTIVE_STARTING_LINE_TRANSPARENCY
    end)

    -- Goo
    raceMaid:GiveTask(DrivingController.setup())
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.Core, nil, function()
    raceMaid:Cleanup()
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.AwardShow, function()
    MinigameScreenUtil.openStandings()
    MinigameScreenUtil.openResults({
        { Title = "Placement", Value = MinigameController.getOwnPlacement() },
        { Title = "Time", Value = MinigameUtil.formatScore(MinigameController.getMinigame(), MinigameController.getOwnScore()) },
        { Title = "Coins Collected", Value = 0 },
        { Title = "Total Coins", Icon = Images.Coins.Coin, Value = 45 },
    })

    if not MinigameController.isMultiplayer() then
        Remotes.fireServer("MinigameRestarted")
        MinigameScreenUtil.openMenu()
    end
end)

return SledRaceController
