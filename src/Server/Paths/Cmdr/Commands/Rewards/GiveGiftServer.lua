local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local RewardsService = require(Paths.Server.RewardsService)

return function(_context, players: { Player }, giftName: string)
    local output = ""

    for _, player in pairs(players) do
        RewardsService.giveGift(player, giftName)
        output ..= (" > Gave %s a %s!\n"):format(player.Name, giftName)
    end

    return output
end
