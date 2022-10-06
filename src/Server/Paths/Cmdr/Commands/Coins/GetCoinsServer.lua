local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CurrencyService = require(Paths.Server.CurrencyService)
local StringUtil = require(Paths.Shared.Utils.StringUtil)

return function(_context, players: { Player })
    local output = ""

    for _, player in pairs(players) do
        output ..= (" > %s has %s Coins\n"):format(player.Name, StringUtil.commaValue(CurrencyService.getCoins(player)))
    end

    return output
end
