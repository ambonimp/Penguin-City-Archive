local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local RewardsService = require(Paths.Server.RewardsService)

return function(_context, players: { Player }, days: number?)
    days = days or 1
    local output = ""

    for _, player in pairs(players) do
        RewardsService.addDailyReward(player, days)
        output ..= (" > %s +%d days\n"):format(player.Name, StringUtil.commaValue(days))
    end

    return output
end
