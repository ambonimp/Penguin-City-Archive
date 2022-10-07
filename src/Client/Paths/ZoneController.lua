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
local Assume = require(Paths.Shared.Assume)
local Transitions = require(Paths.Client.UI.Screens.SpecialEffects.Transitions)

local currentZone = ZoneUtil.zone(ZoneConstants.ZoneType.Room, ZoneConstants.DefaultPlayerZoneState.RoomId)
local zoneMaid = Maid.new()
local isRunningTeleportRequest = false

ZoneController.ZoneChanged = Signal.new() -- {fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone}

-------------------------------------------------------------------------------
-- Arrivals
-------------------------------------------------------------------------------

-- Only invoked when the server has forcefully teleported us somewhere
function ZoneController.teleportingToZoneIn(zone: ZoneConstants.Zone, teleportBuffer: number)
    Output.doDebug(ZoneConstants.DoDebug, "teleportingToZoneIn", teleportBuffer, zone.ZoneType, zone.ZoneId)

    -- Blink Transition
    local blinkDuration = math.min(teleportBuffer, Transitions.BLINK_TWEEN_INFO.Time)
    Transitions.blink(function()
        task.wait(teleportBuffer - blinkDuration)
        ZoneController.arrivedAtZone(zone)
    end, {
        TweenTime = blinkDuration,
    })
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
    -- WARN: Already requesting
    if isRunningTeleportRequest then
        warn("Already running a teleport request!")
        return
    end
    isRunningTeleportRequest = true

    local requestAssume = Assume.new(function()
        print("0")
        local teleportBuffer: number? =
            Remotes.invokeServer("ZoneTeleportRequest", zone.ZoneType, zone.ZoneId, game.Workspace:GetServerTimeNow())
        print("1", teleportBuffer)
        return teleportBuffer
    end)
    requestAssume:Check(function(teleportBuffer: number)
        return teleportBuffer and true or false
    end)
    requestAssume:Run(function()
        -- Start blink, resuming onHalfPoint when we get a response
        task.spawn(Transitions.blink, function()
            -- Wait for Response
            local teleportBuffer = requestAssume:Await()
            if teleportBuffer then
                local validationFinishedOffset = requestAssume:GetValidationFinishTimeframe()
                task.wait(math.max(0, teleportBuffer - validationFinishedOffset))
                ZoneController.arrivedAtZone(zone)
            end

            -- Finished
            isRunningTeleportRequest = false
        end)
    end)
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
        ZoneTeleport = function(zoneType: string, zoneId: string, teleportBuffer: number)
            -- RETURN: This is part of a teleportRequest, which we are already handling
            if isRunningTeleportRequest then
                print("ZoneTeleport return")
                return
            end

            ZoneController.teleportingToZoneIn(ZoneUtil.zone(zoneType, zoneId), teleportBuffer)
        end,
    })
end

return ZoneController
