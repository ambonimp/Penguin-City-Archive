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

PizzaMinigameConstants.IngredientWeightEquations = {
    Toppings = {
        --[[
            We graph toppings' weights over time. We want each topping to have its "reign", so you feel yourself progressing through
            the game as one of the toppings is most frequented
            https://www.desmos.com/calculator/83yw1wfnct
        ]]
        Seaweed = function(alpha: number)
            return -(4 * alpha - 0.8) + 1
        end,
        Squid = function(alpha: number)
            return -(4 * alpha - 1.6) + 1
        end,
        Anchovies = function(alpha: number)
            return -(4 * alpha - 2.4) + 1
        end,
        Shrimp = function(alpha: number)
            return -(4 * alpha - 3.2) + 1
        end,
    } :: { [string]: WeightEquation },
    Sauces = {
        --[[
            We graph a sauces' weight over time. We aim for hotsauce to become more prevelant as the game goes on
            https://www.desmos.com/calculator/iaqdci8seo
        ]]
        TomatoSauce = function(alpha: number)
            return -0.6 * alpha + 1
        end,
        HotSauce = function(alpha: number)
            return 2 * alpha - 0.5
        end,
    } :: { [string]: WeightEquation },
    Bases = {
        -- Never changes!
        Cheese = function(_alpha: number)
            return 1
        end,
    } :: { [string]: WeightEquation },
}

PizzaMinigameConstants.Recipes = {
    A = { Bases = 1, Sauces = 1 },
    B = { Bases = 1, Sauces = 1, Toppings = { 5 } },
    C = { Bases = 1, Sauces = 1, Toppings = { 2, 2 } },
    D = { Bases = 1, Sauces = 1, Toppings = { 1, 1, 1, 1 } },
} :: { [string]: Recipe }

PizzaMinigameConstants.RecipeWeightEquations = {
    --[[
        We graph a recipes weight over time. At any given time, some recipes will be more likely to be chosen than others.
        In first ~11% of the game (at time of writing), only equation A gives a value greater than 0 - so only recipe A will be
        chosen for this time period!
        https://www.desmos.com/calculator/bns1imkyxe
    ]]
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
} :: { [string]: WeightEquation }

return PizzaMinigameConstants
