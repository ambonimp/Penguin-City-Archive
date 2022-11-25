local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local MinigameService = require(Paths.Server.Minigames.MinigameService)

return function(_context, minigame: string, players: { Player }, playSolo: boolean)
    local output = ""
    for _, player in pairs(players) do
        MinigameService.requestToPlay(player, minigame, playSolo)
        output ..= (" > Attempting to play %s for %s\n"):format(minigame, player.Name)
    end

    return output
end
