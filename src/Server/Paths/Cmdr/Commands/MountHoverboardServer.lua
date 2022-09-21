local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)

return function(_context, players: { Player })
    for _, player in pairs(players) do
        --todo mount
    end

    return "Mounted Players"
end
