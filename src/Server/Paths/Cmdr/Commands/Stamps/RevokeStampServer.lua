local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local StampService = require(Paths.Server.Stamps.StampService)
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
        local didOwnBefore = StampService.revokeStamp(player, stampId)
        if didOwnBefore then
            output ..= (" > %s -%q Stamp (%s)\n"):format(player.Name, stamp.DisplayName, stamp.Type)
        else
            output ..= (" > %s never owned the %q Stamp\n"):format(player.Name, stamp.DisplayName)
        end
    end

    return output
end
