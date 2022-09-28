local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local MinigameService = require(Paths.Server.Minigames.MinigameService)
local PizzaMinigameConstants = require(Paths.Shared.Minigames.Pizza.PizzaMinigameConstants)

return function()
    local issues: { string } = {}

    local minigameDirectory = MinigameService.getMinigamesDirectory().Pizza

    -- Assets
    do
        -- Each ingredient has an asset
        local assets: Folder = minigameDirectory.Assets
        for toppingName, ingredients in pairs(PizzaMinigameConstants.Ingredients) do
            for _ingredientName, ingredientName in pairs(ingredients) do
                local asset = assets:FindFirstChild(ingredientName)
                if not asset then
                    table.insert(issues, ("Missing asset for ingredient %s (%s)"):format(ingredientName, toppingName))
                end
            end
        end

        -- Each asset has a primary part
        for _, assetModel: Model in pairs(assets:GetChildren()) do
            if assetModel:IsA("Model") then
                if not assetModel.PrimaryPart then
                    table.insert(issues, ("Asset %s missing PrimaryPart"):format(assetModel:GetFullName()))
                end
            end
        end

        -- Each sauce has a particle emitter
        for _, sauceName in pairs(PizzaMinigameConstants.Ingredients.Sauces) do
            local asset = assets:FindFirstChild(sauceName)
            if asset then
                local particleEmitter = asset:FindFirstChildWhichIsA("ParticleEmitter", true)
                if not particleEmitter then
                    table.insert(issues, ("Asset %s needs a sauce ParticleEmitter"):format(sauceName))
                end
            end
        end

        -- PizzaModel
        local pizzaAsset = assets:FindFirstChild("Pizza")
        if pizzaAsset then
            local ingredients = pizzaAsset:FindFirstChild("Ingredients")
            if not (ingredients and ingredients:IsA("Model")) then
                table.insert(issues, ("Pizza Model %s needs an `Ingredients` Model"):format(pizzaAsset:GetFullName()))
            end
            local sauceParts = pizzaAsset:FindFirstChild("Sauce")
            if not (sauceParts and #sauceParts:GetChildren() > 0) then
                table.insert(issues, ("Pizza Model %s needs a `Sauces` Folder, with sauce parts"):format(pizzaAsset:GetFullName()))
            end
        else
            table.insert(issues, ("No Pizza model in %s"):format(assets:GetFullName()))
        end
    end

    return issues
end
