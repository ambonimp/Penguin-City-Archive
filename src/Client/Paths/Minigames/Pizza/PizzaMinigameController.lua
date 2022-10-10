--[[
    The brain of the pizza minigame. This can create multiple PizzaMinigameRunners
]]
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
local PizzaMinigameConstants = require(Paths.Shared.Minigames.Pizza.PizzaMinigameConstants)
local LightingUtil = require(Paths.Shared.Utils.LightingUtil)
local UIResults = require(Paths.Client.UI.UIResults)
local Images = require(Paths.Shared.Images.Images)

local FOV = 65
local FILLER_RECIPE_ORDER = { PizzaMinigameConstants.FirstRecipe } -- Assumed agreement between Server/Client on start recipe order

local minigameFolder: Folder?
local isStarted = false
local runner: typeof(PizzaMinigameRunner.new(Instance.new("Folder"), {}, function() end)) | nil
local cachedStopMinigameCallback: () -> MinigameConstants.PlayRequest

-------------------------------------------------------------------------------
-- Start/Stop
-------------------------------------------------------------------------------

function PizzaMinigameController.startMinigame(minigamesDirectory: Folder, stopMinigameCallback: () -> MinigameConstants.PlayRequest)
    isStarted = true
    Output.doDebug(MinigameConstants.DoDebug, "startMinigame")

    minigameFolder = minigamesDirectory:WaitForChild("Pizza")
    PizzaMinigameController.setupView()
    cachedStopMinigameCallback = stopMinigameCallback
end

function PizzaMinigameController.stopMinigame()
    isStarted = false
    Output.doDebug(MinigameConstants.DoDebug, "stopMinigame")

    if runner and runner:IsRunning() then
        PizzaMinigameController.finish()
    end
    PizzaMinigameController.clearView()
end

-------------------------------------------------------------------------------
-- Play
-------------------------------------------------------------------------------

local function transitionFinish()
    Transitions.blink(function()
        PizzaMinigameController.finish()
    end)
end

function PizzaMinigameController.play()
    Output.doDebug(MinigameConstants.DoDebug, "play!")

    -- WARN: Not started!
    if not isStarted then
        warn("Not started")
    end

    -- WARN : Already playing
    if runner and runner:IsRunning() then
        warn("Already playing")
    end

    -- Inform server
    Remotes.fireServer("PizzaMinigamePlay")

    -- Transition into gameplay
    runner = PizzaMinigameRunner.new(minigameFolder, FILLER_RECIPE_ORDER, transitionFinish)
    Transitions.blink(function()
        PizzaMinigameController.viewGameplay()
        runner:Run()
    end)
end

function PizzaMinigameController.finish()
    Output.doDebug(MinigameConstants.DoDebug, "finish!")

    -- WARN: Not playing
    if not (runner and runner:IsRunning()) then
        warn("Not playing")
    end

    -- Inform server
    Remotes.fireServer("PizzaMinigameFinsh")

    local stats = runner:GetStats()
    runner:Stop()
    runner = nil

    PizzaMinigameController.viewMenu()
    UIResults.display(Images.PizzaMinigame.Logo, {
        { Name = "Coins", Value = stats.TotalCoins, Icon = Images.Coins.Coin },
        { Name = "Pizzas Made", Value = stats.TotalPizzas, Icon = Images.PizzaMinigame.PizzaBase },
        {
            Name = "Lives Left",
            Value = ("%d/%d"):format((PizzaMinigameConstants.MaxMistakes - stats.TotalMistakes), PizzaMinigameConstants.MaxMistakes),
            Icon = Images.Icons.Heart,
        },
    }, nil)
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
    LightingUtil.resetBlur(0)
end

function PizzaMinigameController.viewMenu()
    PizzaMinigameScreen.viewMenu()
    CameraController.viewCameraModel(minigameFolder.Cameras.Menu)
    LightingUtil.setBlur(MinigameConstants.BlurSize, 0)
end

function PizzaMinigameController.viewGameplay()
    PizzaMinigameScreen.viewGameplay()
    CameraController.viewCameraModel(minigameFolder.Cameras.Gameplay)
    LightingUtil.resetBlur(0)
end

-------------------------------------------------------------------------------
-- Other
-------------------------------------------------------------------------------

-- UI Hooks
do
    PizzaMinigameScreen.getPlayButton().Pressed:Connect(function()
        PizzaMinigameController.play()
    end)
    PizzaMinigameScreen.getExitButton().Pressed:Connect(function()
        cachedStopMinigameCallback()
    end)
    PizzaMinigameScreen.getExitGameplayButton().Pressed:Connect(function()
        transitionFinish()
    end)
    PizzaMinigameScreen.getInstructionsButton().Pressed:Connect(function()
        PizzaMinigameScreen.viewInstructions()
    end)
    PizzaMinigameScreen.getInstructionsCloseButton().Pressed:Connect(function()
        PizzaMinigameScreen.viewMenu()
    end)
end

-- Communication
do
    Remotes.bindEvents({
        PizzaMinigameRecipeTypeOrder = function(recipeOrder: { string })
            if runner then
                Output.doDebug(MinigameConstants.DoDebug, "got recipeOrder", recipeOrder)
                runner:SetRecipeTypeOrder(recipeOrder)
            else
                warn("Received recipeOrder but no runner")
            end
        end,
    })
end

return PizzaMinigameController
