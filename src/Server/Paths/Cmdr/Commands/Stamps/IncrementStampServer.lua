local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local StampService = require(Paths.Server.Stamps.StampService)
local Stamps = require(Paths.Shared.Stamps.Stamps)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)

return function(_context, players: { Player }, _stampType: Stamps.StampType, stampId: string, amount: number)
    local output = ""

    -- RETURN: Bad stampId
    local stamp = StampUtil.getStampFromId(stampId)
    if not stamp then
        return ("Could not find stamp from passed stampId %q"):format(stampId)
    end

    for _, player in pairs(players) do
        StampService.incrementStamp(player, stampId, amount)
        output ..= (" > %s +%q Stamp +%d\n"):format(player.Name, stamp.DisplayName, amount)
    end

    return output
end
