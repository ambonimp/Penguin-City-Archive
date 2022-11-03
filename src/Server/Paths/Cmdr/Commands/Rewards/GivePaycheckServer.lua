local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local RewardsService = require(Paths.Server.RewardsService)

return function(_context, players: { Player })
    local output = ""

    for _, player in pairs(players) do
        RewardsService.givePaycheck(player)
        output ..= (" > Gave %s their next paycheck!\n"):format(player.Name)
    end

    return output
end
