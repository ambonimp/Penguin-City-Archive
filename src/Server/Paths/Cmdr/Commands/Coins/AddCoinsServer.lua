local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CurrencyService = require(Paths.Server.CurrencyService)
local StringUtil = require(Paths.Shared.Utils.StringUtil)

return function(_context, players: { Player }, addCoins: number)
    local output = ""

    for _, player in pairs(players) do
        CurrencyService.addCoins(player, addCoins, true)
        output ..= (" > %s +%s Coins (%s total)\n"):format(
            player.Name,
            StringUtil.commaValue(addCoins),
            StringUtil.commaValue(CurrencyService.getCoins(player))
        )
    end

    return output
end
