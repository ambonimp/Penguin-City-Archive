local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local MinigameService = require(Paths.Server.Minigames.MinigameService)
local PizzaMinigameConstants = require(Paths.Shared.Minigames.Pizza.PizzaMinigameConstants)

return function()
    local issues: { string } = {}

    local minigameDirectory = MinigameService.getMinigamesDirectory().Pizza

    -- Assets
    do
        local assets: Folder = minigameDirectory.Assets
        for toppingName, ingredients in pairs(PizzaMinigameConstants.Ingredients) do
            for _ingredientName, ingredientName in pairs(ingredients) do
                local asset = assets:FindFirstChild(ingredientName)
                if not asset then
                    table.insert(issues, ("Missing asset for ingredient %s (%s)"):format(ingredientName, toppingName))
                end
            end
        end

        for _, assetModel: Model in pairs(assets:GetChildren()) do
            if assetModel:IsA("Model") then
                if not assetModel.PrimaryPart then
                    table.insert(issues, ("Asset %s missing PrimaryPart"):format(assetModel:GetFullName()))
                end
            end
        end
    end

    return issues
end
