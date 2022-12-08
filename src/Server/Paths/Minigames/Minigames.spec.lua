local CollectionService = game:GetService("CollectionService")

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)

return function()
    local issues: { string } = {}

    for _, prompt in pairs(CollectionService:GetTagged("MinigamemPrompt")) do
        local queueStation: Model = prompt.Parent

        local minigameName = queueStation:GetAttribute("Minigame")
        if not minigameName then
            table.insert(issues, ("%s doesn't have a minigame attribute set"):format(prompt:GetFullName()))
        elseif not MinigameConstants.Minigames[minigameName] then
            table.insert(
                issues,
                ("%s doesn't have a valid minigame attribute set, %s isn't a minigame name"):format(prompt:GetFullName(), minigameName)
            )
        end

        local isMultiplayer = queueStation:GetAttribute("Multiplayer")
        if isMultiplayer == nil then
            table.insert(issues, ("%s doesn't have a multiplayer attribute"):format(prompt:GetFullName()))
        end
    end

    return issues
end
