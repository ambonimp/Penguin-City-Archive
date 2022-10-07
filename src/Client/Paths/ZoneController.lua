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

local MAX_YIELD_TIME_ZONE_LOADING = 10

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
        -- Wait to be teleported
        task.wait(teleportBuffer - blinkDuration)

        -- Wait for zone to load
        ZoneController.waitForZoneToLoad(zone)

        -- Announce arrival
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
        local teleportBuffer: number? =
            Remotes.invokeServer("ZoneTeleportRequest", zone.ZoneType, zone.ZoneId, game.Workspace:GetServerTimeNow())
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
                -- Wait for teleport
                local validationFinishedOffset = requestAssume:GetValidationFinishTimeframe()
                task.wait(math.max(0, teleportBuffer - validationFinishedOffset))

                -- Wait for zone to load
                ZoneController.waitForZoneToLoad(zone)

                -- Announce Arrival
                ZoneController.arrivedAtZone(zone)
            else
                warn("Teleport Request not granted")
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
-- Loading
-------------------------------------------------------------------------------

function ZoneController.isZoneLoaded(zone: ZoneConstants.Zone)
    local zoneModel = ZoneUtil.getZoneModel(zone)

    -- Iterate through all instances, checking if all baseparts are loaded
    for _, instance in pairs(zoneModel:GetDescendants()) do
        local totalBaseParts = instance:GetAttribute(ZoneConstants.AttributeBasePartTotal)
        if totalBaseParts then
            local countedBaseParts = 0
            for _, basePart: BasePart in pairs(instance:GetChildren()) do
                if basePart:IsA("BasePart") then
                    countedBaseParts += 1
                end
            end

            -- RETURN FALSE: Has not got all base parts yet
            if countedBaseParts < totalBaseParts then
                return false
            end
        end
    end

    return true
end

function ZoneController.getTotalUnloadedBaseParts(zone: ZoneConstants.Zone)
    local zoneModel = ZoneUtil.getZoneModel(zone)

    local totalUnloadedBaseParts = 0
    for _, instance in pairs(zoneModel:GetDescendants()) do
        local totalBaseParts = instance:GetAttribute(ZoneConstants.AttributeBasePartTotal)
        if totalBaseParts then
            local countedBaseParts = 0
            for _, basePart: BasePart in pairs(instance:GetChildren()) do
                if basePart:IsA("BasePart") then
                    countedBaseParts += 1
                end
            end

            totalUnloadedBaseParts += (totalBaseParts - countedBaseParts)
        end
    end

    return totalUnloadedBaseParts
end

function ZoneController.waitForZoneToLoad(zone: ZoneConstants.Zone)
    if ZoneController.isZoneLoaded(zone) then
        return
    end

    local zoneModel = ZoneUtil.getZoneModel(zone)
    local totalLoadedPastParts = 0
    zoneModel.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            totalLoadedPastParts += 1
        end
    end)

    local totalUnloadedBaseParts = ZoneController.getTotalUnloadedBaseParts(zone)

    local startTick = tick()
    while (totalUnloadedBaseParts > totalLoadedPastParts) and (tick() - startTick < MAX_YIELD_TIME_ZONE_LOADING) do
        task.wait()
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
