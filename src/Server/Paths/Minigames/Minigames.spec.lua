local CollectionService = game:GetService("CollectionService")

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)

return function()
    local issues: { string } = {}

    for _, minigamePrompt in pairs(CollectionService:GetTagged("MinigamePrompt")) do
        local minigameName = minigamePrompt:GetAttribute("Minigame")
        if not minigameName then
            table.insert(issues, ("%s doesn't have a minigame attribute set"):format(minigamePrompt:GetFullName()))
        elseif not MinigameConstants.Minigames[minigameName] then
            table.insert(
                issues,
                ("%s doesn't have a valid minigame attribute set, %s isn't a minigame name"):format(
                    minigamePrompt:GetFullName(),
                    minigameName
                )
            )
        end

        if minigamePrompt:GetAttribute("Multiplayer") == nil then
            table.insert(issues, ("%s doesn't have a multiplayer attribute"):format(minigamePrompt:GetFullName()))
        end
    end

    return issues
end
