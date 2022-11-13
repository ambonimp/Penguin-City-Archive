--[[
    The brain of the pizza minigame. This can create multiple PizzaFiascoRunners
]]
local PizzaFiascoController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Images = require(Paths.Shared.Images.Images)
local Remotes = require(Paths.Shared.Remotes)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local SharedMinigameScreen = require(Paths.Client.UI.Screens.Minigames.SharedMinigameScreen)
local CameraController = require(Paths.Client.CameraController)
local PizzaFiascoRunner = require(Paths.Client.Minigames.PizzaFiasco.PizzaFiascoRunner)
local PizzaFiascoConstants = require(Paths.Shared.Minigames.PizzaFiasco.PizzaFiascoConstants)
local Output = require(Paths.Shared.Output)

local FILLER_RECIPE_ORDER = { PizzaFiascoConstants.FirstRecipe } -- Assumed agreement between Server/Client on start recipe order

local RUNNER_JANITOR_INDEX = "PizzaFiascoRunner"

local MINIGAME_NAME = "PizzaFiasco"

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local minigameJanitor = MinigameController.getMinigameJanitor()
local runner: typeof(PizzaFiascoRunner.new(Instance.new("Model"), {}, function() end)) | nil

-------------------------------------------------------------------------------
-- State handlers
-------------------------------------------------------------------------------
MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.Nothing, function()
    SharedMinigameScreen.openStartMenu()
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.Core, function()
    local map = MinigameController.getMap()

    SharedMinigameScreen.closeStartMenu()
    CameraController.viewCameraModel(map.Cameras.Gameplay)

    minigameJanitor:Add(
        PizzaFiascoRunner.new(map, FILLER_RECIPE_ORDER, function()
            Remotes.fireServer("PizzaFiascoPizzaCompleted")
        end),
        "Stop",
        RUNNER_JANITOR_INDEX
    )
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.AwardShow, function()
    local stats = runner:GetStats()
    runner:Stop()
    minigameJanitor:Remove(RUNNER_JANITOR_INDEX)
    runner = nil

    task.wait(1)
    SharedMinigameScreen.openResults({
        { Title = "Coins", Value = stats.TotalCoins, Icon = Images.Coins.Coin },
        { Title = "Pizzas Made", Value = stats.TotalPizzas, Icon = Images.PizzaFiasco.PizzaBase },
        {
            Title = "Lives Left",
            Value = ("%d/%d"):format((PizzaFiascoConstants.MaxMistakes - stats.TotalMistakes), PizzaFiascoConstants.MaxMistakes),
            Icon = Images.Icons.Heart,
        },
    })

    Remotes.fireServer("MinigameRestarted")
    SharedMinigameScreen.openStartMenu()
end)

-------------------------------------------------------------------------------
-- Other
-------------------------------------------------------------------------------
-- Communication
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

-- Reset any camera changes
minigameJanitor:Add(function()
    CameraController.resetFov()
    CameraController.setPlayerControl()
end)

return PizzaFiascoController
