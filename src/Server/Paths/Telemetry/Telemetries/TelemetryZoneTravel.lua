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

        -- Make igloo zones a bit more readable..
        local toZoneType = toZone.ZoneType
        if ZoneUtil.isHouseInteriorZone(toZone) then
            local isOwnIgloo = ZoneUtil.zonesMatch(toZone, ZoneUtil.houseInteriorZone(player))
            toZoneType = isOwnIgloo and "igloo" or "visitIgloo"
        end

        local fromZoneType = fromZone.ZoneType
        if ZoneUtil.isHouseInteriorZone(fromZone) then
            local isOwnIgloo = ZoneUtil.zonesMatch(fromZone, ZoneUtil.houseInteriorZone(player))
            fromZoneType = isOwnIgloo and "igloo" or "visitIgloo"
        end

        -- Post
        TelemetryService.postPlayerEvent(player, "zoneTravel", {
            zoneFrom = ("%s_%s"):format(StringUtil.case(fromZone.ZoneCategory), StringUtil.toCamelCase(fromZoneType)),
            zoneTo = ("%s_%s"):format(StringUtil.toCamelCase(toZone.ZoneCategory), StringUtil.toCamelCase(toZoneType)),
            travelMethod = StringUtil.toCamelCase(teleportData.TravelMethod or ZoneConstants.TravelMethod.Unknown),
        })
    end
)

return TelemetryZoneTravel
