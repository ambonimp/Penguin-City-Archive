local PizzaMinigameConstants = {}

type Recipe = {
    Bases: number, -- How many base ingredients are needed
    Sauces: number, -- How many sauces are needed
    Toppings: { number } | nil, -- How many toppings are needed, and how many of each topping
}

type WeightEquation = (alpha: number) -> number

PizzaMinigameConstants.Reward = {
    Base = 5, -- Base coins to reward for 1 correct pizza
    IncreaseEvery = 5, -- Increase the coin reward every x correct pizzas
    IncreaseBy = 5, -- How much to increase the coin reward by
}

PizzaMinigameConstants.Conveyor = {
    Speed = 10, -- How many seconds the pizza is on screen for
    IncreaseFactor = 0.9, -- How much to decrease the time on screen by
}

PizzaMinigameConstants.MaxMistakes = 3
PizzaMinigameConstants.MaxPizzas = 40

PizzaMinigameConstants.Ingredients = {
    Toppings = {
        Seaweed = "Seaweed",
        Squid = "Squid",
        Anchovies = "Anchovies",
        Shrimp = "Shrimp",
    },
    Sauces = {
        TomatoSauce = "Tomato Sauce",
        HotSauce = "Hot Sauce",
    },
    Bases = {
        Cheese = "Cheese",
    },
}

local toppingsWeightEquations: { [string]: WeightEquation } = {}
local saucesWeightEquations: { [string]: WeightEquation } = {}
local basesWeightEquations: { [string]: WeightEquation } = {}
PizzaMinigameConstants.IngredientWeightEquations = {
    Toppings = toppingsWeightEquations,
    Sauces = saucesWeightEquations,
    Bases = basesWeightEquations,
}

local recipes: { [string]: Recipe } = {
    A = { Bases = 1, Sauces = 1 },
    B = { Bases = 1, Sauces = 1, Toppings = { 5 } },
    C = { Bases = 1, Sauces = 1, Toppings = { 2, 2 } },
    D = { Bases = 1, Sauces = 1, Toppings = { 1, 1, 1, 1 } },
}
PizzaMinigameConstants.Recipes = recipes

--[[
    We graph a recipes weight over time. At any given time, some recipes will be more likely to be chosen than others.
    In first ~11% of the game (at time of writing), only equation A gives a value greater than 0 - so only recipe A will be
    chosen for this time period!
    https://www.desmos.com/calculator/bns1imkyxe
]]
local recipeWeightEquations: { [string]: WeightEquation } = {
    A = function(alpha: number)
        return -1.3 * alpha + 1
    end,
    B = function(alpha: number)
        return alpha ^ 4
    end,
    C = function(alpha: number)
        return -(2.5 * alpha - 1) ^ 2 + 0.5
    end,
    D = function(alpha: number)
        return -(2.8 * alpha - 1.5) ^ 2 + 0.6
    end,
}
PizzaMinigameConstants.RecipeWeightEquations = recipeWeightEquations

return PizzaMinigameConstants
