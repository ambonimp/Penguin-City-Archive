local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local StampService = require(Paths.Server.StampService)
local Stamps = require(Paths.Shared.Stamps.Stamps)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)

return function(_context, players: { Player }, _stampType: Stamps.StampType, stampId: string, stampTier: Stamps.StampTier | nil)
    local output = ""

    -- RETURN: Bad stampId
    local stamp = StampUtil.getStampFromId(stampId)
    if not stamp then
        return ("Could not find stamp from passed stampId %q"):format(stampId)
    end

    if stamp.IsTiered then
        stampTier = stampTier or "Bronze"
    else
        stampTier = nil
    end

    for _, player in pairs(players) do
        local owns = StampService.hasStamp(player, stampId, stampTier)
        local tierSuffix = stamp.IsTiered and ("[%s] "):format(stampTier) or ""
        if owns then
            output ..= (" > %s owns the %q %sStamp (%s)\n"):format(player.Name, stamp.DisplayName, tierSuffix, stamp.Type)
        else
            output ..= (" > %s does not own the %q %sStamp (%s)\n"):format(player.Name, stamp.DisplayName, tierSuffix, stamp.Type)
        end
    end

    return output
end
