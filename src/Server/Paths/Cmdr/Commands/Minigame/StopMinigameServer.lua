local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)

return function(_context, players: { Player })
    local output = ""
    for _, player in pairs(players) do
        require(Paths.Server.Cmdr.CmdrService).invokeClientLogic(player, "StopMinigame")
        output ..= (" > Attempting to stop minigame for %s\n"):format(player.Name)
    end

    return output
end
