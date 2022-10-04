local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)

return function(_context, minigame: string, players: { Player })
    local output = ""
    for _, player in pairs(players) do
        require(Paths.Server.Cmdr.CmdrService).invokeClientLogic(player, "StartMinigame", minigame)
        output ..= (" > Attempting to play %s for %s\n"):format(minigame, player.Name)
    end

    return output
end
