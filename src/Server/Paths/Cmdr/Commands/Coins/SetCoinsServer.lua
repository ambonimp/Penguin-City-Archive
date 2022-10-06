local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CurrencyService = require(Paths.Server.CurrencyService)
local StringUtil = require(Paths.Shared.Utils.StringUtil)

return function(_context, players: { Player }, coins: number)
    local output = ""

    for _, player in pairs(players) do
        CurrencyService.setCoins(player, coins, true)
        output ..= (" > %s now has %s Coins\n"):format(player.Name, StringUtil.commaValue(coins))
    end

    return output
end
