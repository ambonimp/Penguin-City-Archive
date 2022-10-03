--[[
    This class acts both as storage for our current order, as well as the order sign UI
]]
local PizzaMinigameOrder = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local PizzaMinigameConstants = require(Paths.Shared.Minigames.Pizza.PizzaMinigameConstants)
local PizzaMinigameUtil = require(Paths.Shared.Minigames.Pizza.PizzaMinigameUtil)
local MathUtil = require(Paths.Shared.Utils.MathUtil)

export type OrderEntry = { IngredientName: string, IngredientType: string, Current: number, Needed: number }
export type Order = { OrderEntry }

local STRIKETHROUGH_ROTATION_RANGE = NumberRange.new(-3, 3)

function PizzaMinigameOrder.new(surfaceGui: SurfaceGui)
    local orderObject = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local pizzaTitle = "Waiting for order.."
    local pizzasMade = 0
    local mistakes = 0
    local coinsEarnt = 0

    local order: Order = {}

    local elements = {
        pizzaTitle = surfaceGui.Frame.PizzaTitle.TextLabel :: TextLabel,
        pizzas = surfaceGui.Frame.Stats.Pizzas.Value :: TextLabel,
        mistakes = surfaceGui.Frame.Stats.Mistakes :: TextLabel,
        coins = surfaceGui.Frame.Coins.Value :: TextLabel,
        order = surfaceGui.Frame.Ingredients :: Frame,
        ingredientsTemplate = surfaceGui.Frame.Ingredients.template :: TextLabel,
    }

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function draw()
        -- Static
        elements.pizzaTitle.Text = pizzaTitle
        elements.pizzas.Text = ("%d/%d"):format(pizzasMade, PizzaMinigameConstants.MaxPizzas)
        elements.coins.Text = ("%d"):format(coinsEarnt)

        -- Mistakes
        do
            for i = 1, PizzaMinigameConstants.MaxMistakes do
                local hasLife = mistakes < i
                elements.mistakes[i].Visible = hasLife
            end
        end

        -- Ingredients
        do
            -- Read current labels
            local currentIngredientElements: { [string]: Frame } = {}
            for _, child in pairs(elements.order:GetChildren()) do
                if child:IsA(elements.ingredientsTemplate.ClassName) and child ~= elements.ingredientsTemplate then
                    currentIngredientElements[child.Name] = child
                end
            end

            -- Get / Create needed labels
            local ingredientElements: { [string]: Frame } = {}
            for i, ingredient in pairs(order) do
                local ingredientName = ingredient.IngredientName

                local ingredientFrame = elements.order:FindFirstChild(ingredientName)
                if not ingredientFrame then
                    ingredientFrame = elements.ingredientsTemplate:Clone()
                    ingredientFrame.Name = ingredientName
                    ingredientFrame.Visible = true
                    ingredientFrame.LayoutOrder = i
                    ingredientFrame.Icon.Image = PizzaMinigameUtil.getIngredientIconId(ingredientName)
                    ingredientFrame.Parent = elements.order
                end

                ingredientElements[ingredientName] = ingredientFrame
                currentIngredientElements[ingredientName] = nil
            end

            -- Cull old labels
            for _, oldLabel in pairs(currentIngredientElements) do
                oldLabel:Destroy()
            end

            -- Write
            for _, ingredient in pairs(order) do
                local ingredientFrame = ingredientElements[ingredient.IngredientName]

                local text = PizzaMinigameUtil.getNiceName(ingredient.IngredientName)
                if ingredient.IngredientType == PizzaMinigameConstants.IngredientTypes.Toppings then
                    text = ("x%d %s"):format(ingredient.Needed, ingredient.IngredientName)
                end

                local isCompleted = ingredient.Current >= ingredient.Needed
                if isCompleted and ingredientFrame.Strikethrough.Visible == false then
                    ingredientFrame.Strikethrough.Rotation = MathUtil.nextNumberInRange(STRIKETHROUGH_ROTATION_RANGE)
                    ingredientFrame.Strikethrough.Visible = true
                elseif not isCompleted then
                    ingredientFrame.Strikethrough.Visible = false
                end

                ingredientFrame.TextLabel.Text = text
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
            { IngredientName = recipe.Sauce, IngredientType = PizzaMinigameConstants.IngredientTypes.Sauces, Current = 0, Needed = 1 },
            { IngredientName = recipe.Base, IngredientType = PizzaMinigameConstants.IngredientTypes.Bases, Current = 0, Needed = 1 },
        }
        for toppingName, toppingAmount in pairs(recipe.Toppings) do
            table.insert(order, {
                IngredientName = toppingName,
                IngredientType = PizzaMinigameConstants.IngredientTypes.Toppings,
                Current = 0,
                Needed = toppingAmount,
            })
        end

        draw()
    end

    function orderObject:SetPizzaCounts(newPizzasMade: number, newMistakes: number)
        pizzasMade = newPizzasMade
        mistakes = newMistakes

        draw()
    end

    function orderObject:SetCoinsEarnt(newCoinsEarnt: number)
        coinsEarnt = newCoinsEarnt

        draw()
    end

    --[[
        - true: Ingredient successfully added!
        - false: Bad ingredient / too many added
    ]]
    function orderObject:IngredientAdded(ingredientName: string)
        for _, ingredient in pairs(order) do
            if ingredient.IngredientName == ingredientName and ingredient.Current < ingredient.Needed then
                ingredient.Current += 1
                draw()
                return true
            end
        end

        return false
    end

    function orderObject:IsOrderFulfilled()
        for _, ingredient in pairs(order) do
            if ingredient.Current < ingredient.Needed then
                return false
            end
        end

        return true
    end

    function orderObject:GetCurrentOrder()
        return order
    end

    -------------------------------------------------------------------------------
    -- Logic
    -------------------------------------------------------------------------------

    elements.ingredientsTemplate.Visible = false
    elements.ingredientsTemplate.Strikethrough.Visible = false
    draw()

    return orderObject
end

return PizzaMinigameOrder
