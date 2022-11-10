--[[
    The brain of the pizza minigame. This can create multiple PizzaFiascoRunners
]]
local PizzaFiascoController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local Output = require(Paths.Shared.Output)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local PizzaFiascoScreen = require(Paths.Client.UI.Screens.Minigames.PizzaFiascoScreen)
local CameraController = require(Paths.Client.CameraController)
local Transitions = require(Paths.Client.UI.Screens.SpecialEffects.Transitions)
local PizzaFiascoRunner = require(Paths.Client.Minigames.PizzaFiasco.PizzaFiascoRunner)
local Remotes = require(Paths.Shared.Remotes)
local PizzaFiascoConstants = require(Paths.Shared.Minigames.PizzaFiasco.PizzaFiascoConstants)
local LightingUtil = require(Paths.Shared.Utils.LightingUtil)
local UIResults = require(Paths.Client.UI.UIResults)
local Images = require(Paths.Shared.Images.Images)

local FOV = 65
local FILLER_RECIPE_ORDER = { PizzaFiascoConstants.FirstRecipe } -- Assumed agreement between Server/Client on start recipe order

local minigameFolder: Folder?
local isStarted = false
local runner: typeof(PizzaFiascoRunner.new(Instance.new("Folder"), {}, function() end)) | nil
local cachedStopMinigameCallback: () -> MinigameConstants.PlayRequest

-------------------------------------------------------------------------------
-- Start/Stop
-------------------------------------------------------------------------------

function PizzaFiascoController.startMinigame(minigamesDirectory: Folder, stopMinigameCallback: () -> MinigameConstants.PlayRequest)
    isStarted = true
    Output.doDebug(MinigameConstants.DoDebug, "startMinigame")

    minigameFolder = minigamesDirectory:WaitForChild("Pizza")
    PizzaFiascoController.setupView()
    cachedStopMinigameCallback = stopMinigameCallback
end

function PizzaFiascoController.stopMinigame()
    isStarted = false
    Output.doDebug(MinigameConstants.DoDebug, "stopMinigame")

    if runner and runner:IsRunning() then
        PizzaFiascoController.finish()
    end
    PizzaFiascoController.clearView()
end

-------------------------------------------------------------------------------
-- Play
-------------------------------------------------------------------------------

local function transitionFinish()
    Transitions.blink(function()
        PizzaFiascoController.finish()
    end)
end

function PizzaFiascoController.play()
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
    Remotes.fireServer("PizzaFiascoPlay")

    -- Transition into gameplay
    runner = PizzaFiascoRunner.new(minigameFolder, FILLER_RECIPE_ORDER, transitionFinish)
    Transitions.blink(function()
        PizzaFiascoController.viewGameplay()
        runner:Run()
    end)
end

function PizzaFiascoController.finish()
    Output.doDebug(MinigameConstants.DoDebug, "finish!")

    -- WARN: Not playing
    if not (runner and runner:IsRunning()) then
        warn("Not playing")
    end

    -- Inform server
    Remotes.fireServer("PizzaFiascoFinsh")

    local stats = runner:GetStats()
    runner:Stop()
    runner = nil

    PizzaFiascoController.viewMenu()
    UIResults.display(Images.PizzaFiasco.Logo, {
        { Name = "Coins", Value = stats.TotalCoins, Icon = Images.Coins.Coin },
        { Name = "Pizzas Made", Value = stats.TotalPizzas, Icon = Images.PizzaFiasco.PizzaBase },
        {
            Name = "Lives Left",
            Value = ("%d/%d"):format((PizzaFiascoConstants.MaxMistakes - stats.TotalMistakes), PizzaFiascoConstants.MaxMistakes),
            Icon = Images.Icons.Heart,
        },
    }, nil)
end

-------------------------------------------------------------------------------
-- Views
-------------------------------------------------------------------------------

function PizzaFiascoController.setupView()
    UIController.getStateMachine():PushIfMissing(UIConstants.States.PizzaFiasco)
    CameraController.setScriptable()
    CameraController.setFov(FOV, 0)

    PizzaFiascoController.viewMenu()
end

function PizzaFiascoController.clearView()
    UIController.getStateMachine():Remove(UIConstants.States.PizzaFiasco)
    CameraController.setPlayerControl()
    CameraController.resetFov(0)
    LightingUtil.resetBlur(0)
end

function PizzaFiascoController.viewMenu()
    PizzaFiascoScreen.viewMenu()
    CameraController.viewCameraModel(minigameFolder.Cameras.Menu)
    LightingUtil.setBlur(MinigameConstants.BlurSize, 0)
end

function PizzaFiascoController.viewGameplay()
    PizzaFiascoScreen.viewGameplay()
    CameraController.viewCameraModel(minigameFolder.Cameras.Gameplay)
    LightingUtil.resetBlur(0)
end

-------------------------------------------------------------------------------
-- Other
-------------------------------------------------------------------------------

-- Communication
do
    Remotes.bindEvents({
        PizzaFiascoRecipeTypeOrder = function(recipeOrder: { string })
            if runner then
                Output.doDebug(MinigameConstants.DoDebug, "got recipeOrder", recipeOrder)
                runner:SetRecipeTypeOrder(recipeOrder)
            else
                warn("Received recipeOrder but no runner")
            end
        end,
    })
end

return PizzaFiascoController
