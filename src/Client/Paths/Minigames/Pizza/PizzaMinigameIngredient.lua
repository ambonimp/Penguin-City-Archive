--[[
    Class that represents an ingredient the client is currently holding
]]
local PizzaMinigameIngredient = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)

type PizzaMinigameRunner = typeof(require(Paths.Client.Minigames.Pizza.PizzaMinigameRunner).new(Instance.new("Folder"), {}))

function PizzaMinigameIngredient.new(runner: PizzaMinigameRunner, ingredientType: string, ingredientName: string)
    local ingredient = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local maid = Maid.new()
    local asset: Model = runner:GetMinigameFolder().Assets[ingredientName]
    asset.Parent = runner:GetGameplayFolder()

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    --todo

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function tickIngredient(dt: number)
        --todo
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function ingredient:Destroy()
        maid:Destroy()
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    maid:GiveTask(RunService.RenderStepped:Connect(function(dt)
        tickIngredient(dt)
    end))

    return ingredient
end

return PizzaMinigameIngredient
