local PizzaMinigameUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PizzaMinigameConstants = require(script.Parent.PizzaMinigameConstants)
local MathUtil = require(ReplicatedStorage.Modules.Utils.MathUtil)

function PizzaMinigameUtil.rollRecipe(pizzasCompleted: number)
    local alpha = pizzasCompleted / PizzaMinigameConstants.MaxPizzas

    local weightTable: { [string]: number } = {}
    for recipeLabel, weightEquation in pairs(PizzaMinigameConstants.RecipeWeightEquations) do
        local weight = weightEquation(alpha)
        weightTable[recipeLabel] = weight
    end

    local selectedRecipeLabel: string = MathUtil.selectKeyFromValueWeights(weightTable)
    local recipe = PizzaMinigameConstants.Recipes[selectedRecipeLabel]

    return recipe
end

return PizzaMinigameUtil
