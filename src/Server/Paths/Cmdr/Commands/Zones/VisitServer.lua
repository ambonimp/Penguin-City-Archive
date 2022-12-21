local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)

return function(_context, players: { Player }, player: Player)
    local zone = ZoneUtil.houseInteriorZone(player)

    local output = ""
    for _, somePlayer in pairs(players) do
        task.spawn(ZoneService.teleportPlayerToZone, somePlayer, zone, {
            TravelMethod = ZoneConstants.TravelMethod.Cmdr,
        })

        output ..= (" > %s is off to %s igloo!\n"):format(somePlayer.Name, StringUtil.possessiveName(player.Name))
    end

    return output
end
