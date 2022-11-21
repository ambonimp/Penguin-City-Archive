local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)

return function(_context, players: { Player }, zoneCategory: string, zoneType: string)
    local zone = ZoneUtil.zone(zoneCategory, zoneType)

    local output = ""
    for _, player in pairs(players) do
        task.spawn(ZoneService.teleportPlayerToZone, player, zone)

        output ..= (" > %s is off to the %s.%s Zone!\n"):format(player.Name, zoneCategory, zoneType)
    end

    return output
end
