local PizzaMinigameController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local Output = require(Paths.Shared.Output)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local PizzaMinigameScreen = require(Paths.Client.UI.Screens.Minigames.PizzaMinigame.PizzaMinigameScreen)
local Camera = require(Paths.Client.Camera)
local Transitions = require(Paths.Client.UI.Screens.SpecialEffects.Transitions)
local PizzaMinigameRunner = require(Paths.Client.Minigames.Pizza.PizzaMinigameRunner)

local FOV = 65

local minigameFolder: Folder?
local isStarted = false

-------------------------------------------------------------------------------
-- Start/Stop
-------------------------------------------------------------------------------

function PizzaMinigameController.startMinigame(minigamesDirectory: Folder)
    isStarted = true
    Output.doDebug(MinigameConstants.DoDebug, "startMinigame")

    minigameFolder = minigamesDirectory:WaitForChild("Pizza")
    --TODO Ensure that minigameFolder is fully loaded in

    Transitions.blink(function()
        PizzaMinigameController.setupView()
    end)
end

function PizzaMinigameController.stopMinigame()
    isStarted = false
    Output.doDebug(MinigameConstants.DoDebug, "stopMinigame")

    Transitions.blink(function()
        PizzaMinigameRunner.stop()
        PizzaMinigameController.clearView()
    end)
end

-------------------------------------------------------------------------------
-- Play
-------------------------------------------------------------------------------

function PizzaMinigameController.play()
    -- ERROR: Not started!
    if not isStarted then
        error("Not started")
    end
    Output.doDebug(MinigameConstants.DoDebug, "play!")

    Transitions.blink(function()
        PizzaMinigameController.viewGameplay()
        PizzaMinigameRunner.run(minigameFolder)
    end)
end

-------------------------------------------------------------------------------
-- Views
-------------------------------------------------------------------------------

function PizzaMinigameController.setupView()
    UIController.getStateMachine():PushIfMissing(UIConstants.States.PizzaMinigame)
    Camera.setScriptable()
    Camera.setFov(FOV, 0)

    PizzaMinigameController.viewMenu()
end

function PizzaMinigameController.clearView()
    UIController.getStateMachine():Remove(UIConstants.States.PizzaMinigame)
    Camera.setPlayerControl()
    Camera.resetFov(0)
end

function PizzaMinigameController.viewMenu()
    PizzaMinigameScreen.viewMenu()
    Camera.viewCameraModel(minigameFolder.Cameras.Menu)
end

function PizzaMinigameController.viewGameplay()
    PizzaMinigameScreen.viewGameplay()
    Camera.viewCameraModel(minigameFolder.Cameras.Gameplay)
end

-------------------------------------------------------------------------------
-- UI Hooks
-------------------------------------------------------------------------------

do
    PizzaMinigameScreen.getPlayButton().Pressed:Connect(function()
        PizzaMinigameController.play()
    end)
    PizzaMinigameScreen.getInstructionsButton().Pressed:Connect(function()
        warn("TODO Instructions")
    end)
end

return PizzaMinigameController
