local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)

return function(_context, players: { Player }, roomType: string)
    local zone = ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, roomType)

    local output = ""
    for _, player in pairs(players) do
        ZoneService.teleportPlayerToZone(player, zone)
        output ..= (" > Teleporting %s to %s\n"):format(player.Name, roomType)
    end

    return output
end
