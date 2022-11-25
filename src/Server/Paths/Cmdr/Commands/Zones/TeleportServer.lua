local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local Remotes = require(Paths.Shared.Remotes)

return function(_context, players: { Player }, zoneType: string, zoneId: string)
    -- RETURN: Room Only
    if zoneType ~= ZoneConstants.ZoneType.Room then
        return ("Cannot teleport to zonetype %q; %q only!"):format(zoneType, ZoneConstants.ZoneType.Room)
    end

    local output = ""
    for _, player in pairs(players) do
        Remotes.fireClient(player, "CmdrRoomTeleport", zoneId)

        output ..= (" > %s is off to the %s.%s Zone!\n"):format(player.Name, zoneType, zoneId)
    end

    return output
end
