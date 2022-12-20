local TelemetryZoneTravel = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local TelemetryService = require(Paths.Server.Telemetry.TelemetryService)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)

ZoneService.ZoneChanged:Connect(
    function(player: Player, fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone, teleportData: ZoneConstants.TeleportData)
        -- RETURN: Don't post initial teleport by server
        if teleportData.IsInitialTeleport then
            return
        end

        -- Post
        TelemetryService.postPlayerEvent(player, "zoneTravel", {
            zoneFrom = ZoneUtil.toString(player, fromZone),
            zoneTo = ZoneUtil.toString(player, toZone),
            travelMethod = StringUtil.toCamelCase(teleportData.TravelMethod or ZoneConstants.TravelMethod.Unknown),
        })
    end
)

return TelemetryZoneTravel
