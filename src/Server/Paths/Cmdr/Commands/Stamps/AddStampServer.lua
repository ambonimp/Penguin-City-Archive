local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local StampService = require(Paths.Server.StampService)
local Stamps = require(Paths.Shared.Stamps.Stamps)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)

return function(_context, players: { Player }, _stampType: Stamps.StampType, stampId: string)
    local output = ""

    -- RETURN: Bad stampId
    local stamp = StampUtil.getStampFromId(stampId)
    if not stamp then
        return ("Could not find stamp from passed stampId %q"):format(stampId)
    end

    for _, player in pairs(players) do
        local didNotOwnBefore = StampService.addStamp(player, stampId)
        if didNotOwnBefore then
            output ..= (" > %s +%q Stamp (%s)\n"):format(player.Name, stamp.DisplayName, stamp.Type)
        else
            output ..= (" > %s already owns the %q Stamp\n"):format(player.Name, stamp.DisplayName)
        end
    end

    return output
end
