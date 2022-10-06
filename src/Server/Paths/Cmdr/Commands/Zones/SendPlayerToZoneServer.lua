local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)

return function(_context, players: { Player }, zoneType: string, zoneId: string)
    local zone = ZoneUtil.zone(zoneType, zoneId)

    local output = ""
    for _, player in pairs(players) do
        task.spawn(ZoneService.sendPlayerToZone, player, zone)

        output ..= (" > %s is off to the %s.%s Zone!\n"):format(player.Name, zoneType, zoneId)
    end

    return output
end
