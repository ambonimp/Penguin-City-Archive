local PizzaMinigameController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local Output = require(Paths.Shared.Output)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local PizzaMinigameScreen = require(Paths.Client.UI.Screens.Minigames.PizzaMinigame.PizzaMinigameScreen)
local CameraController = require(Paths.Client.CameraController)
local Transitions = require(Paths.Client.UI.Screens.SpecialEffects.Transitions)
local PizzaMinigameRunner = require(Paths.Client.Minigames.Pizza.PizzaMinigameRunner)
local Remotes = require(Paths.Shared.Remotes)
local Promise = require(Paths.Packages.promise)
local PizzaMinigameConstants = require(Paths.Shared.Minigames.Pizza.PizzaMinigameConstants)

local FOV = 65

local minigameFolder: Folder?
local isStarted = false
local runner: typeof(PizzaMinigameRunner.new(Instance.new("Folder"), {})) | nil
local cachedRecipeTypeOrder: { string } | nil

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
        if runner then
            runner:Stop()
            runner = nil
        end

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

    -- ERROR: No cached recipe order
    if not cachedRecipeTypeOrder then
        error("No cached recipe order")
    end

    Output.doDebug(MinigameConstants.DoDebug, "play!")

    Transitions.blink(function()
        PizzaMinigameController.viewGameplay()

        runner = PizzaMinigameRunner.new(minigameFolder, cachedRecipeTypeOrder or { PizzaMinigameConstants.FirstRecipe })
        runner:Run()

        cachedRecipeTypeOrder = nil
    end)
end

-------------------------------------------------------------------------------
-- Views
-------------------------------------------------------------------------------

function PizzaMinigameController.setupView()
    UIController.getStateMachine():PushIfMissing(UIConstants.States.PizzaMinigame)
    CameraController.setScriptable()
    CameraController.setFov(FOV, 0)

    PizzaMinigameController.viewMenu()
end

function PizzaMinigameController.clearView()
    UIController.getStateMachine():Remove(UIConstants.States.PizzaMinigame)
    CameraController.setPlayerControl()
    CameraController.resetFov(0)
end

function PizzaMinigameController.viewMenu()
    PizzaMinigameScreen.viewMenu()
    CameraController.viewCameraModel(minigameFolder.Cameras.Menu)
end

function PizzaMinigameController.viewGameplay()
    PizzaMinigameScreen.viewGameplay()
    CameraController.viewCameraModel(minigameFolder.Cameras.Gameplay)
end

-------------------------------------------------------------------------------
-- Other
-------------------------------------------------------------------------------

-- UI Hooks
do
    PizzaMinigameScreen.getPlayButton().Pressed:Connect(function()
        PizzaMinigameController.play()
    end)
    PizzaMinigameScreen.getInstructionsButton().Pressed:Connect(function()
        warn("TODO Instructions")
    end)
end

-- Communication
do
    Remotes.bindEvents({
        PizzaMinigameRecipeTypeOrder = function(recipeOrder: { string })
            if runner then
                runner:SetRecipeTypeOrder(recipeOrder)
            else
                cachedRecipeTypeOrder = recipeOrder
            end
        end,
    })
end

return PizzaMinigameController
