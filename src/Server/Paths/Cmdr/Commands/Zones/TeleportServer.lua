local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local Remotes = require(Paths.Shared.Remotes)

return function(_context, players: { Player }, zoneCategory: string, zoneType: string)
    -- RETURN: Room Only
    if zoneCategory ~= ZoneConstants.ZoneCategory.Room then
        return ("Cannot teleport to category %q; %q only!"):format(zoneCategory, ZoneConstants.ZoneCategory.Room)
    end

    local output = ""
    for _, player in pairs(players) do
        Remotes.fireClient(player, "CmdrRoomTeleport", zoneType)

        output ..= (" > %s is off to the %s.%s Zone!\n"):format(player.Name, zoneCategory, zoneType)
    end

    return output
end
