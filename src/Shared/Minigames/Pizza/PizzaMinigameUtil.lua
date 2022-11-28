--[[
    Has a lot of "rollers"; gives us a random recipeType/sauce/etc.. dependent on our current progress in the game.
    Some convenient getters too.
]]
local PizzaMinigameUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PizzaMinigameConstants = require(script.Parent.PizzaMinigameConstants)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local Images = require(ReplicatedStorage.Shared.Images.Images)

export type Recipe = {
    Base: string,
    Sauce: string,
    Toppings: { [string]: number },
}

local TOTAL_TOPPINGS = TableUtil.length(PizzaMinigameConstants.Ingredients.Toppings)
local NICE_NAMES = {
    HotSauce = "Hot Sauce",
    TomatoSauce = "Tomato Sauce",
}

function PizzaMinigameUtil.rollRecipeType(pizzaNumber: number)
    local alpha = pizzaNumber / PizzaMinigameConstants.MaxPizzas

    local weightTable: { { Weight: number, Value: any } } = {}
    for recipeLabel, weightEquation in pairs(PizzaMinigameConstants.RecipeTypeWeightEquations) do
        local weight = math.clamp(weightEquation(alpha), 0, 1)
        table.insert(weightTable, {
            Weight = weight,
            Value = recipeLabel,
        })
    end

    local selectedRecipeLabel: string = MathUtil.weightedChoice(weightTable)
    local recipeType = PizzaMinigameConstants.RecipeTypes[selectedRecipeLabel]

    return selectedRecipeLabel, recipeType
end

function PizzaMinigameUtil.rollToppings(pizzaNumber: number, toppingsNeeded: number)
    local alpha = pizzaNumber / PizzaMinigameConstants.MaxPizzas

    -- ERROR: Too many toppings!
    if toppingsNeeded > TOTAL_TOPPINGS then
        error(("Requested to roll %d toppings, only %d toppings exist!"):format(toppingsNeeded, TOTAL_TOPPINGS))
    end

    local weightTable: { { Weight: number, Value: any } } = {}
    local totalWeight = 0
    for topping, weightEquation in pairs(PizzaMinigameConstants.IngredientWeightEquations.Toppings) do
        local weight = math.clamp(weightEquation(alpha), 0, 1)
        if weight > 0 then
            totalWeight += weight
            table.insert(weightTable, {
                Weight = weight,
                Value = topping,
            })
        end
    end

    local toppings: { string } = {}
    for _ = 1, toppingsNeeded do
        if TableUtil.isEmpty(weightTable) then
            -- Empty weight table is bad! Just choose a random topping in this case.
            for _, toppingName in pairs(PizzaMinigameConstants.Ingredients.Toppings) do
                if not table.find(toppings, toppingName) then
                    table.insert(toppings, toppingName)
                    break
                end
            end
        else
            local selectedTopping: string = MathUtil.weightedChoice(weightTable)
            table.insert(toppings, selectedTopping)
            for index, entry in pairs(weightTable) do
                if entry.Value == selectedTopping then
                    table.remove(weightTable, index)
                    break
                end
            end
        end
    end

    return toppings
end

function PizzaMinigameUtil.rollSauce(pizzaNumber: number)
    local alpha = pizzaNumber / PizzaMinigameConstants.MaxPizzas

    local weightTable: { { Weight: number, Value: any } } = {}
    for sauce, weightEquation in pairs(PizzaMinigameConstants.IngredientWeightEquations.Sauces) do
        local weight = math.clamp(weightEquation(alpha), 0, 1)
        table.insert(weightTable, {
            Weight = weight,
            Value = sauce,
        })
    end

    return MathUtil.weightedChoice(weightTable) :: string
end

function PizzaMinigameUtil.rollBase(pizzaNumber: number)
    local alpha = pizzaNumber / PizzaMinigameConstants.MaxPizzas

    local weightTable: { { Weight: number, Value: any } } = {}
    for base, weightEquation in pairs(PizzaMinigameConstants.IngredientWeightEquations.Bases) do
        local weight = math.clamp(weightEquation(alpha), 0, 1)
        table.insert(weightTable, {
            Weight = weight,
            Value = base,
        })
    end

    return MathUtil.weightedChoice(weightTable) :: string
end

function PizzaMinigameUtil.rollRecipe(pizzaNumber: number, recipeType: PizzaMinigameConstants.RecipeType?)
    recipeType = recipeType or PizzaMinigameUtil.rollRecipeType(pizzaNumber)

    local recipe: Recipe = {
        Base = PizzaMinigameUtil.rollBase(pizzaNumber),
        Sauce = PizzaMinigameUtil.rollSauce(pizzaNumber),
        Toppings = {},
    }

    local toppings = PizzaMinigameUtil.rollToppings(pizzaNumber, #recipeType.Toppings)
    for i, topping in pairs(toppings) do
        recipe.Toppings[topping] = recipeType.Toppings[i]
    end

    return recipe
end

-- Gives the reward for completing this specific pizza number
function PizzaMinigameUtil.calculatePizzaReward(pizzaNumber: number)
    local increaseCount = math.floor((pizzaNumber - 1) / PizzaMinigameConstants.Reward.IncreaseEvery)
    return PizzaMinigameConstants.Reward.Base + increaseCount * PizzaMinigameConstants.Reward.IncreaseBy
end

function PizzaMinigameUtil.getRecipeName(recipe: Recipe)
    local ingredients = PizzaMinigameConstants.Ingredients
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
function PizzaMinigameUtil.getNiceName(someString: string)
    return NICE_NAMES[someString] or someString
end

function PizzaMinigameUtil.getIngredientIconId(ingredientName: string)
    local imageId = Images.PizzaMinigame[ingredientName]
    if not imageId then
        warn(("Could not get ImageId for ingredient %q"):format(ingredientName))
        imageId = ""
    end

    return imageId
end

return PizzaMinigameUtil
