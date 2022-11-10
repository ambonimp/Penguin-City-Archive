--[[
    Has a lot of "rollers"; gives us a random recipeType/sauce/etc.. dependent on our current progress in the game.
    Some convenient getters too.
]]
local PizzaFiascoUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PizzaFiascoConstants = require(script.Parent.PizzaFiascoConstants)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local Images = require(ReplicatedStorage.Shared.Images.Images)

export type Recipe = {
    Base: string,
    Sauce: string,
    Toppings: { [string]: number },
}

local TOTAL_TOPPINGS = TableUtil.length(PizzaFiascoConstants.Ingredients.Toppings)
local NICE_NAMES = {
    HotSauce = "Hot Sauce",
    TomatoSauce = "Tomato Sauce",
}

function PizzaFiascoUtil.rollRecipeType(pizzaNumber: number)
    local alpha = pizzaNumber / PizzaFiascoConstants.MaxPizzas

    local weightTable: { [string]: number } = {}
    for recipeLabel, weightEquation in pairs(PizzaFiascoConstants.RecipeTypeWeightEquations) do
        local weight = math.clamp(weightEquation(alpha), 0, 1)
        weightTable[recipeLabel] = weight
    end

    local selectedRecipeLabel: string = MathUtil.weightedChoice(weightTable)
    local recipeType = PizzaFiascoConstants.RecipeTypes[selectedRecipeLabel]

    return selectedRecipeLabel, recipeType
end

function PizzaFiascoUtil.rollToppings(pizzaNumber: number, toppingsNeeded: number)
    local alpha = pizzaNumber / PizzaFiascoConstants.MaxPizzas

    -- ERROR: Too many toppings!
    if toppingsNeeded > TOTAL_TOPPINGS then
        error(("Requested to roll %d toppings, only %d toppings exist!"):format(toppingsNeeded, TOTAL_TOPPINGS))
    end

    local weightTable: { [string]: number } = {}
    for topping, weightEquation in pairs(PizzaFiascoConstants.IngredientWeightEquations.Toppings) do
        local weight = math.clamp(weightEquation(alpha), 0, 1)
        weightTable[topping] = weight
    end

    local toppings: { string } = {}
    for _ = 1, toppingsNeeded do
        local totalWeight = TableUtil.sumValues(weightTable)
        if totalWeight > 0 then
            local selectedTopping: string = MathUtil.weightedChoice(weightTable)
            table.insert(toppings, selectedTopping)
            weightTable[selectedTopping] = nil
        else
            local _, selectedTopping = TableUtil.getRandom(weightTable)
            table.insert(toppings, selectedTopping)
        end
    end

    return toppings
end

function PizzaFiascoUtil.rollSauce(pizzaNumber: number)
    local alpha = pizzaNumber / PizzaFiascoConstants.MaxPizzas

    local weightTable: { [string]: number } = {}
    for sauce, weightEquation in pairs(PizzaFiascoConstants.IngredientWeightEquations.Sauces) do
        local weight = math.clamp(weightEquation(alpha), 0, 1)
        weightTable[sauce] = weight
    end

    return MathUtil.weightedChoice(weightTable) :: string
end

function PizzaFiascoUtil.rollBase(pizzaNumber: number)
    local alpha = pizzaNumber / PizzaFiascoConstants.MaxPizzas

    local weightTable: { [string]: number } = {}
    for base, weightEquation in pairs(PizzaFiascoConstants.IngredientWeightEquations.Bases) do
        local weight = math.clamp(weightEquation(alpha), 0, 1)
        weightTable[base] = weight
    end

    return MathUtil.weightedChoice(weightTable) :: string
end

function PizzaFiascoUtil.rollRecipe(pizzaNumber: number, recipeType: PizzaFiascoConstants.RecipeType?)
    recipeType = recipeType or PizzaFiascoUtil.rollRecipeType(pizzaNumber)

    local recipe: Recipe = {
        Base = PizzaFiascoUtil.rollBase(pizzaNumber),
        Sauce = PizzaFiascoUtil.rollSauce(pizzaNumber),
        Toppings = {},
    }

    local toppings = PizzaFiascoUtil.rollToppings(pizzaNumber, #recipeType.Toppings)
    for i, topping in pairs(toppings) do
        recipe.Toppings[topping] = recipeType.Toppings[i]
    end

    return recipe
end

-- Gives the reward for completing this specific pizza number
function PizzaFiascoUtil.calculatePizzaReward(pizzaNumber: number)
    local increaseCount = math.floor((pizzaNumber - 1) / PizzaFiascoConstants.Reward.IncreaseEvery)
    return PizzaFiascoConstants.Reward.Base + increaseCount * PizzaFiascoConstants.Reward.IncreaseBy
end

function PizzaFiascoUtil.getRecipeName(recipe: Recipe)
    local ingredients = PizzaFiascoConstants.Ingredients
    local totalToppings = TableUtil.length(recipe.Toppings)

    -- No Toppings
    if totalToppings == 0 then
        if recipe.Base == ingredients.Bases.Cheese and recipe.Sauce == ingredients.Sauces.TomatoSauce then
            return "Margherita"
        end
        if recipe.Base == ingredients.Bases.Cheese and recipe.Sauce == ingredients.Sauces.HotSauce then
            return "Plain 'n' Spicy"
        end

        return "?No Toppings?"
    end

    -- Toppings
    local prefix = recipe.Sauce == ingredients.Sauces.HotSauce and "Spicy " or ""

    local toppingsCombo = ""
    if totalToppings <= 3 then
        local totalToppingsScribed = 0
        for toppingName, _ in pairs(recipe.Toppings) do
            local suffix = (totalToppingsScribed + 1) < totalToppings and "-" or ""
            toppingsCombo ..= ("%s%s"):format(toppingName, suffix)
            totalToppingsScribed += 1
        end
    else
        toppingsCombo = "Bonanza"
    end

    return ("%s%s"):format(prefix, toppingsCombo)
end

-- Useful to convert a "data-scoped" name to something appropriate to show to a user
function PizzaFiascoUtil.getNiceName(someString: string)
    return NICE_NAMES[someString] or someString
end

function PizzaFiascoUtil.getIngredientIconId(ingredientName: string)
    local imageId = Images.PizzaFiasco[ingredientName]
    if not imageId then
        warn(("Could not get ImageId for ingredient %q"):format(ingredientName))
        imageId = ""
    end

    return imageId
end

return PizzaFiascoUtil
