local PizzaMinigameUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PizzaMinigameConstants = require(script.Parent.PizzaMinigameConstants)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local TOTAL_TOPPINGS = TableUtil.length(PizzaMinigameConstants.Ingredients.Toppings)

function PizzaMinigameUtil.rollRecipe(pizzaNumber: number)
    local alpha = pizzaNumber / PizzaMinigameConstants.MaxPizzas

    local weightTable: { [string]: number } = {}
    for recipeLabel, weightEquation in pairs(PizzaMinigameConstants.RecipeWeightEquations) do
        local weight = math.clamp(weightEquation(alpha), 0, 1)
        weightTable[recipeLabel] = weight
    end

    local selectedRecipeLabel: string = MathUtil.selectKeyFromValueWeights(weightTable)
    local recipe = PizzaMinigameConstants.Recipes[selectedRecipeLabel]

    return recipe
end

function PizzaMinigameUtil.rollToppings(pizzaNumber: number, toppingsNeeded: number)
    local alpha = pizzaNumber / PizzaMinigameConstants.MaxPizzas

    -- ERROR: Too many toppings!
    if toppingsNeeded > TOTAL_TOPPINGS then
        error(("Requested to roll %d toppings, only %d toppings exist!"):format(toppingsNeeded, TOTAL_TOPPINGS))
    end

    local weightTable: { [string]: number } = {}
    for topping, weightEquation in pairs(PizzaMinigameConstants.IngredientWeightEquations.Toppings) do
        local weight = math.clamp(weightEquation(alpha), 0, 1)
        weightTable[topping] = weight
    end

    local toppings: { string } = {}
    for _ = 1, toppingsNeeded do
        local selectedTopping: string = MathUtil.selectKeyFromValueWeights(weightTable)
        table.insert(toppings, selectedTopping)
        weightTable[selectedTopping] = nil
    end

    return toppings
end

function PizzaMinigameUtil.rollSauce(pizzaNumber: number)
    local alpha = pizzaNumber / PizzaMinigameConstants.MaxPizzas

    local weightTable: { [string]: number } = {}
    for sauce, weightEquation in pairs(PizzaMinigameConstants.IngredientWeightEquations.Sauces) do
        local weight = math.clamp(weightEquation(alpha), 0, 1)
        weightTable[sauce] = weight
    end

    return MathUtil.selectKeyFromValueWeights(weightTable) :: string
end

function PizzaMinigameUtil.rollBase(pizzaNumber: number)
    local alpha = pizzaNumber / PizzaMinigameConstants.MaxPizzas

    local weightTable: { [string]: number } = {}
    for base, weightEquation in pairs(PizzaMinigameConstants.IngredientWeightEquations.Bases) do
        local weight = math.clamp(weightEquation(alpha), 0, 1)
        weightTable[base] = weight
    end

    return MathUtil.selectKeyFromValueWeights(weightTable) :: string
end

-- Gives the reward for completing this specific pizza number
function PizzaMinigameUtil.calculatePizzaReward(pizzaNumber: number)
    local increaseCount = math.floor((pizzaNumber - 1) / PizzaMinigameConstants.Reward.IncreaseEvery)
    return PizzaMinigameConstants.Reward.Base + increaseCount * PizzaMinigameConstants.Reward.IncreaseBy
end

return PizzaMinigameUtil
