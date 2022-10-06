local ZoneController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local Remotes = require(Paths.Shared.Remotes)
local Output = require(Paths.Shared.Output)
local Signal = require(Paths.Shared.Signal)
local Maid = require(Paths.Packages.maid)
local PlayersHitbox = require(Paths.Shared.PlayersHitbox)

local currentZone = ZoneUtil.zone(ZoneConstants.ZoneType.Room, ZoneConstants.DefaultPlayerZoneState.RoomId)
local zoneMaid = Maid.new()

ZoneController.ZoneChanged = Signal.new() -- {fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone}

-------------------------------------------------------------------------------
-- Arrivals
-------------------------------------------------------------------------------

function ZoneController.arrivingToZoneIn(zone: ZoneConstants.Zone, teleportBuffer: number)
    Output.doDebug(ZoneConstants.DoDebug, "arrivingToZoneIn", teleportBuffer, zone.ZoneType, zone.ZoneId)

    task.wait(teleportBuffer)

    ZoneController.arrivedAtZone(zone)
end

function ZoneController.arrivedAtZone(zone: ZoneConstants.Zone)
    Output.doDebug(ZoneConstants.DoDebug, "arrivedAtZone", zone.ZoneType, zone.ZoneId)

    -- Clean up old zone
    zoneMaid:Cleanup()

    -- Init new Zone
    currentZone = zone
    ZoneController.setupTeleporters()

    -- Inform Client
    ZoneController.ZoneChanged:Fire(currentZone, zone)
end

-------------------------------------------------------------------------------
-- Teleports
-------------------------------------------------------------------------------

function ZoneController.teleportRequest(zone: ZoneConstants.Zone)
    warn("todo teleportRequest")
end

function ZoneController.setupTeleporters()
    local zoneInstances = ZoneUtil.getZoneInstances(currentZone)
    for _, zoneType in pairs(ZoneConstants.ZoneType) do
        local departuresName = ("%sDepartures"):format(zoneType)
        local departuresInstances = zoneInstances[departuresName]
        if departuresInstances then
            for _, teleporter in pairs(departuresInstances:GetChildren()) do
                local zoneId = teleporter.Name
                local zone = ZoneUtil.zone(zoneType, zoneId)

                local playersHitbox = PlayersHitbox.new():AddPart(teleporter)
                zoneMaid:GiveTask(playersHitbox)

                playersHitbox.PlayerEntered:Connect(function(player: Player)
                    -- RETURN: Not local player
                    if player ~= Players.LocalPlayer then
                        return
                    end

                    ZoneController.teleportRequest(zone)
                end)
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Logic
-------------------------------------------------------------------------------

-- Communication
do
    Remotes.bindEvents({
        ZoneChanged = function(zoneType: string, zoneId: string, teleportBuffer: number)
            ZoneController.arrivingToZoneIn(ZoneUtil.zone(zoneType, zoneId), teleportBuffer)
        end,
    })
end

return ZoneController
