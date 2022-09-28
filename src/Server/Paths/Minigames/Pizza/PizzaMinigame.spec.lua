local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local MinigameService = require(Paths.Server.Minigames.MinigameService)

return function()
    local issues: { string } = {}

    local minigameDirectory = MinigameService.getMinigamesDirectory().Pizza

    -- Assets
    do
        for _, assetModel: Model in pairs(minigameDirectory.Assets:GetChildren()) do
            if assetModel:IsA("Model") then
                if not assetModel.PrimaryPart then
                    table.insert(issues, ("Asset %s missing PrimaryPart"):format(assetModel:GetFullName()))
                end
            end
        end
    end

    return issues
end
