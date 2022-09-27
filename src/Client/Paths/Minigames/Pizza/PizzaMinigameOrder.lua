--[[
    This class acts both as storage for our current order, as well as the order sign UI
]]
local PizzaMinigameOrder = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local PizzaMinigameConstants = require(Paths.Shared.Minigames.Pizza.PizzaMinigameConstants)
local PizzaMinigameUtil = require(Paths.Shared.Minigames.Pizza.PizzaMinigameUtil)

export type OrderEntry = { IngredientName: string, IngredientType: string, Current: number, Needed: number }
export type Order = { OrderEntry }

local COLOR_INGREDIENT_COMPLETED = Color3.fromRGB(80, 199, 12)
local INGREDIENT_TYPE = {
    BASE = "BASE",
    SAUCE = "SAUCE",
    TOPPING = "TOPPING",
}

function PizzaMinigameOrder.new(surfaceGui: SurfaceGui?)
    local orderObject = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local pizzaTitle = "Pizza"
    local pizzasMade = 0
    local pizzasLeft = PizzaMinigameConstants.MaxPizzas
    local mistakes = 0
    local coinsEarnt = 0

    local order: Order = {}

    local elements = {
        pizzaTitle = surfaceGui.Frame.PizzaTitle :: TextLabel,
        pizzasMade = surfaceGui.Frame.Stats.PizzasMade :: TextLabel,
        pizzasLeft = surfaceGui.Frame.Stats.PizzasLeft :: TextLabel,
        mistakes = surfaceGui.Frame.Stats.Mistakes :: TextLabel,
        coins = surfaceGui.Frame.Coins :: TextLabel,
        order = surfaceGui.Frame.Ingredients :: Frame,
        ingredientsTemplate = surfaceGui.Frame.Ingredients.template :: TextLabel,
    }

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function draw()
        -- Static
        elements.pizzaTitle.Text = pizzaTitle
        elements.pizzasMade.Text = ("Pizzas Made: %d"):format(pizzasMade)
        elements.pizzasLeft.Text = ("Pizzas Left: %d"):format(pizzasLeft)
        elements.mistakes.Text = ("Mistakes: %d"):format(mistakes)
        elements.coins.Text = ("%d Coins"):format(coinsEarnt)

        -- Ingredients
        do
            -- Read current labels
            local currentIngredientElements: { [string]: TextLabel } = {}
            for _, child in pairs(elements.order:GetChildren()) do
                if child:IsA(elements.ingredientsTemplate.ClassName) and child ~= elements.ingredientsTemplate then
                    currentIngredientElements[child.Name] = child
                end
            end

            -- Get / Create needed labels
            local ingredientElements: { [string]: TextLabel } = {}
            for i, ingredient in pairs(order) do
                local ingredientName = ingredient.IngredientName

                local ingredientLabel = elements.order:FindFirstChild(ingredientName)
                if not ingredientLabel then
                    ingredientLabel = elements.ingredientsTemplate:Clone()
                    ingredientLabel.Name = ingredientName
                    ingredientLabel.Visible = true
                    ingredientLabel.LayoutOrder = i
                    ingredientLabel.Parent = elements.order
                end

                ingredientElements[ingredientName] = ingredientLabel
                currentIngredientElements[ingredientName] = nil
            end

            -- Cull old labels
            for _, oldLabel in pairs(currentIngredientElements) do
                oldLabel:Destroy()
            end

            -- Write
            for _, ingredient in pairs(order) do
                local ingredientLabel = ingredientElements[ingredient.IngredientName]

                local text = ingredient.IngredientName
                if ingredient.IngredientType == INGREDIENT_TYPE.TOPPING then
                    text = ("%d %s"):format(ingredient.Needed, ingredient.IngredientName)
                end

                local textColor = ingredient.Current == ingredient.Needed and COLOR_INGREDIENT_COMPLETED or ingredientLabel.TextColor3

                ingredientLabel.Text = text
                ingredientLabel.TextColor3 = textColor
            end
        end
    end

    -------------------------------------------------------------------------------
    -- Public Members
    -------------------------------------------------------------------------------

    --[[
        Sets a new recipe and clears the last order
    ]]
    function orderObject:SetRecipe(recipe: PizzaMinigameUtil.Recipe)
        -- Title
        pizzaTitle = ("%s Pizza"):format(PizzaMinigameUtil.getRecipeName(recipe))

        -- Ingredients
        order = {
            { IngredientName = recipe.Sauce, IngredientType = INGREDIENT_TYPE.SAUCE, Current = 0, Needed = 1 },
            { IngredientName = recipe.Base, IngredientType = INGREDIENT_TYPE.BASE, Current = 0, Needed = 1 },
        }
        for toppingName, toppingAmount in pairs(recipe.Toppings) do
            table.insert(order, {
                IngredientName = toppingName,
                IngredientType = INGREDIENT_TYPE.TOPPING,
                Current = 0,
                Needed = toppingAmount,
            })
        end

        draw()
    end

    function orderObject:SetPizzaCounts(newPizzasMade: number, newPizzasLeft: number, newMistakes: number)
        pizzasMade = newPizzasMade
        pizzasLeft = newPizzasLeft
        mistakes = newMistakes

        draw()
    end

    function orderObject:SetCoinsEarnt(newCoinsEarnt: number)
        coinsEarnt = newCoinsEarnt

        draw()
    end

    function orderObject:IngredientAdded(ingredientName: string)
        for _, ingredient in pairs(order) do
            if ingredient.IngredientName == ingredientName then
                ingredient.Current += 1
                draw()
                return
            end
        end

        warn(("No internal ingredient %q"):format(ingredientName))
    end

    function orderObject:GetCurrentOrder()
        return order
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    elements.ingredientsTemplate.Visible = false
    draw()

    return orderObject
end

return PizzaMinigameOrder
