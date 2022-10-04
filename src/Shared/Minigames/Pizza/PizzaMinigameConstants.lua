local PizzaMinigameConstants = {}

export type RecipeType = {
    Toppings: { number } | nil, -- How many toppings are needed, and how many of each topping
}

type WeightEquation = (alpha: number) -> number

PizzaMinigameConstants.Reward = {
    Base = 5, -- Base coins to reward for 1 correct pizza
    IncreaseEvery = 5, -- Increase the coin reward every x pizzas
    IncreaseBy = 5, -- How much to increase the coin reward by
}

PizzaMinigameConstants.Conveyor = {
    Time = 12, -- How many seconds the pizza takes to traverse the conveyor
    IncreaseFactor = 0.95, -- How much to decrease this time by each iteration
    MaxIncreases = 10,
}

PizzaMinigameConstants.MaxMistakes = 3
PizzaMinigameConstants.MaxPizzas = 30

PizzaMinigameConstants.IngredientTypes = {
    Toppings = "Toppings",
    Sauces = "Sauces",
    Bases = "Bases",
}

PizzaMinigameConstants.Ingredients = {
    Toppings = {
        Seaweed = "Seaweed",
        Squid = "Squid",
        Anchovy = "Anchovy",
        Shrimp = "Shrimp",
    },
    Sauces = {
        TomatoSauce = "TomatoSauce",
        HotSauce = "HotSauce",
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
            https://www.desmos.com/calculator/labxavf1ss
        ]]
        Seaweed = function(alpha: number)
            return -(4 * alpha - 0.8) + 1
        end,
        Shrimp = function(alpha: number)
            return -(4 * alpha - 1.6) + 1
        end,
        Squid = function(alpha: number)
            return -(4 * alpha - 2.4) + 1
        end,
        Anchovy = function(alpha: number)
            return -(4 * alpha - 3.2) + 1
        end,
    } :: { [string]: WeightEquation },
    Sauces = {
        --[[
            We graph a sauces' weight over time. We aim for hotsauce to become more prevelant as the game goes on
            https://www.desmos.com/calculator/6shrx9vdgk
        ]]
        TomatoSauce = function(alpha: number)
            return -0.8 * alpha + 0.8
        end,
        HotSauce = function(alpha: number)
            return alpha
        end,
    } :: { [string]: WeightEquation },
    Bases = {
        -- Never changes!
        Cheese = function(_alpha: number)
            return 1
        end,
    } :: { [string]: WeightEquation },
}

-- Ranked in order of what the developer thinks is increasing difficulty
PizzaMinigameConstants.RecipeTypes = {
    A = { Toppings = {} },
    C = { Toppings = { 2 } },
    B = { Toppings = { 1, 1 } },
    D = { Toppings = { 2, 2 } },
    E = { Toppings = { 1, 1, 1, 1 } },
    F = { Toppings = { 5 } },
    G = { Toppings = { 2, 2, 1 } },
} :: { [string]: RecipeType }

PizzaMinigameConstants.RecipeTypeWeightEquations = {
    --[[
        We graph a recipes weight over time. At any given time, some recipes will be more likely to be chosen than others.
        In first ~11% of the game (at time of writing), only equation A gives a value greater than 0 - so only recipe A will be
        chosen for this time period!
        https://www.desmos.com/calculator/o31n3nkixv
    ]]
    A = function(alpha: number)
        return -1 * alpha + 0.5
    end,
    B = function(alpha: number)
        return -(4 * alpha - 1) ^ 2 + 0.5
    end,
    C = function(alpha: number)
        return -(4 * alpha - 1.5) ^ 2 + 0.5
    end,
    D = function(alpha: number)
        return -(4 * alpha - 2) ^ 2 + 0.5
    end,
    E = function(alpha: number)
        return -(4 * alpha - 2.5) ^ 2 + 0.5
    end,
    F = function(alpha: number)
        return -(4 * alpha - 3) ^ 2 + 0.5
    end,
    G = function(alpha: number)
        return alpha ^ 8
    end,
} :: { [string]: WeightEquation }

PizzaMinigameConstants.FirstRecipe = "A" -- Force first recipe

return PizzaMinigameConstants
