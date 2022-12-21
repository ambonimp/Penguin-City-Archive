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
local ZoneController = require(Paths.Client.Zones.ZoneController)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local Output = require(Paths.Shared.Output)
local Confetti = require(Paths.Client.UI.Screens.SpecialEffects.Confetti)

local MINIGAME_NAME = "PizzaFiasco"
local FILLER_RECIPE_ORDER = { PizzaFiascoConstants.FirstRecipe } -- Assumed agreement between Server/Client on start recipe order

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local player = Players.LocalPlayer

local minigameMaid = MinigameController.getMinigameMaid()
local runner: typeof(PizzaFiascoRunner.new(Instance.new("Model"), {}, function() end)) | nil

local runnerTask
-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function stopRunner()
    runner:Stop()
    runner = nil
    runnerTask = nil
end

-------------------------------------------------------------------------------
-- State handlers
-------------------------------------------------------------------------------
MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.Nothing, function()
    SharedMinigameScreen.openStartMenu()

    -- Disable movement
    minigameMaid:GiveTask(task.spawn(function()
        if ZoneController.getCurrentZone().ZoneCategory ~= ZoneConstants.ZoneCategory.Minigame then
            ZoneController.ZoneChanged:Wait()
        end
        CharacterUtil.anchor(player.Character)
    end))

    -- Revert changes
    minigameMaid:GiveTask(function()
        CameraController.resetFov()
        CameraController.setPlayerControl()
        CharacterUtil.unanchor(player.Character)
    end)

    MinigameController.playMusic("Intermission")
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.Intermission, function()
    runner = PizzaFiascoRunner.new(MinigameController.getMap(), FILLER_RECIPE_ORDER, function()
        Remotes.fireServer("PizzaMinigameRoundFinished")
    end)
    runnerTask = minigameMaid:GiveTask(stopRunner)
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.Core, function()
    MinigameController.stopMusic("Intermission")
    SharedMinigameScreen.toggleExitButton(true)
    SharedMinigameScreen.closeStartMenu(false, function()
        CameraController.viewCameraModel(MinigameController.getMap().Cameras.Gameplay)
        runner:Run()
    end)
end, function()
    SharedMinigameScreen.toggleExitButton(false)
end)

MinigameController.registerStateCallback(MINIGAME_NAME, MinigameConstants.States.AwardShow, function(data)
    MinigameController.playMusic("Intermission")
    Confetti.play()

    local stats = runner:GetStats()
    minigameMaid:EndTask(runnerTask)

    SharedMinigameScreen.openResults({
        { Title = "Attempted Pizzas", Value = stats.TotalPizzas, Icon = Images.PizzaFiasco.PizzaBase },
        {
            Title = "Pizzas Completed",
            Value = stats.TotalPizzas - stats.TotalMistakes,
            Icon = Images.PizzaFiasco.PizzaBase,
            Tag = MinigameController.isNewBest(data.Scores) and "New Best",
        },
        { Title = "Coins", Value = stats.TotalCoins, Icon = Images.Coins.Coin },
        --[[ {
            Title = "Lives Left",
            Value = ("%d/%d"):format((PizzaFiascoConstants.MaxMistakes - stats.TotalMistakes), PizzaFiascoConstants.MaxMistakes),
            Icon = Images.Icons.Heart,
        }, *]]
    })

    Remotes.fireServer("MinigameRestarted")
    SharedMinigameScreen.openStartMenu()
end)

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

return PizzaFiascoController
