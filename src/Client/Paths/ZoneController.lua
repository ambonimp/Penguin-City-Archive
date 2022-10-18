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
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local BooleanUtil = require(Paths.Shared.Utils.BooleanUtil)
local MinigameController: typeof(require(Paths.Client.Minigames.MinigameController))

local MAX_YIELD_TIME_ZONE_LOADING = 10
local WAIT_FOR_ZONE_TO_LOAD_INTERMISSION = 1 -- How often to verify if all base parts are loaded

local localPlayer = Players.LocalPlayer
local currentZone = ZoneUtil.zone(ZoneConstants.ZoneType.Room, ZoneConstants.DefaultPlayerZoneState.RoomId)
local currentRoomZone = currentZone
local zoneMaid = Maid.new()
local isRunningTeleportToRoomRequest = false
local isPlayingTransition = false

ZoneController.ZoneChanged = Signal.new() -- {fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone}

function ZoneController.Init()
    MinigameController = require(Paths.Client.Minigames.MinigameController)
end

-------------------------------------------------------------------------------
-- Getters
-------------------------------------------------------------------------------

function ZoneController.getCurrentZone()
    return currentZone
end

function ZoneController.getCurrentRoomZone()
    return currentRoomZone
end

-------------------------------------------------------------------------------
-- Arrivals
-------------------------------------------------------------------------------

local function setupTeleporters()
    for _, zoneType in pairs(ZoneConstants.ZoneType) do
        local departures = ZoneUtil.getDepartures(currentZone, zoneType)
        if departures then
            for _, teleporter: BasePart in pairs(departures:GetChildren()) do
                local zoneId = teleporter.Name
                local zone = ZoneUtil.zone(zoneType, zoneId)

                -- Teleporter
                do
                    local teleporterHitbox = PlayersHitbox.new():AddPart(teleporter)
                    zoneMaid:GiveTask(teleporterHitbox)

                    teleporterHitbox.PlayerEntered:Connect(function(player: Player)
                        -- RETURN: Not local player
                        if player ~= Players.LocalPlayer then
                            return
                        end

                        if zone.ZoneType == ZoneConstants.ZoneType.Room then
                            ZoneController.teleportToRoomRequest(zone)
                        elseif zone.ZoneType == ZoneConstants.ZoneType.Minigame then
                            MinigameController.play(zone.ZoneId)
                        else
                            warn(("%s wat"):format(zone.ZoneType))
                        end
                    end)
                end
            end
        end
    end
end

-- Only invoked when the server has forcefully teleported us somewhere
function ZoneController.teleportingToZoneIn(zone: ZoneConstants.Zone, teleportBuffer: number)
    Output.doDebug(ZoneConstants.DoDebug, "teleportingToZoneIn", teleportBuffer, zone.ZoneType, zone.ZoneId)

    local blinkDuration = math.min(teleportBuffer, Transitions.BLINK_TWEEN_INFO.Time)
    ZoneController.transitionToZone(zone, function()
        -- Wait to be teleported
        task.wait(teleportBuffer - blinkDuration)
    end, nil, { TweenTime = blinkDuration })
end

--[[
    Centralised logic for playing a transition mid-teleport, when we're not sure if the teleport will be granted - and then runs internal routines!
    - `yielder`: Stop yielding this function when we can exit the transition (e.g., have recieved server response, has been teleported)
    - `verifier` (optional): Return true. Returning false indicates the teleport was aborted, and will not run internal routines

    Yields.
]]
function ZoneController.transitionToZone(
    toZone: ZoneConstants.Zone,
    yielder: () -> nil,
    verifier: (() -> boolean)?,
    blinkOptions: (Transitions.BlinkOptions)?
)
    -- RETURN: Already playing
    if isPlayingTransition then
        return
    end

    -- Populate blink options
    blinkOptions = blinkOptions or {}
    blinkOptions.DoAlignCamera = BooleanUtil.returnFirstBoolean(blinkOptions.DoAlignCamera, true)

    isPlayingTransition = true

    Transitions.blink(function()
        yielder()

        if not verifier or verifier() == true then
            -- Init character
            local character = localPlayer.Character
            if character then
                CharacterUtil.anchor(character)
            end

            -- Wait for zone to load
            ZoneController.waitForZoneToLoad(toZone)

            -- Revert character
            if character then
                CharacterUtil.unanchor(character)
            end

            -- Announce Arrival
            ZoneController.arrivedAtZone(toZone)
        end
    end, blinkOptions)

    isPlayingTransition = false
end

function ZoneController.arrivedAtZone(zone: ZoneConstants.Zone)
    Output.doDebug(ZoneConstants.DoDebug, "arrivedAtZone", zone.ZoneType, zone.ZoneId)

    -- Clean up old zone
    zoneMaid:Cleanup()

    -- Init new Zone
    currentZone = zone
    if currentZone.ZoneType == ZoneConstants.ZoneType.Room then
        currentRoomZone = currentZone
    end

    -- Zone Settings
    ZoneUtil.applySettings(zone)
    zoneMaid:GiveTask(function()
        ZoneUtil.revertSettings(zone)
    end)

    setupTeleporters()

    -- Inform Client
    ZoneController.ZoneChanged:Fire(currentZone, zone)
end

-------------------------------------------------------------------------------
-- Teleports
-------------------------------------------------------------------------------

-- Returns our Assume object
function ZoneController.teleportToRoomRequest(roomZone: ZoneConstants.Zone)
    -- WARN: Already requesting
    if isRunningTeleportToRoomRequest then
        warn("Already running a teleport request!")
        return
    end
    isRunningTeleportToRoomRequest = true

    -- ERROR: Not a room!
    if roomZone.ZoneType ~= ZoneConstants.ZoneType.Room then
        error("Not passed a room zone!")
    end

    local requestAssume = Assume.new(function()
        local teleportBuffer: number? =
            Remotes.invokeServer("RoomZoneTeleportRequest", roomZone.ZoneType, roomZone.ZoneId, game.Workspace:GetServerTimeNow())
        return teleportBuffer
    end)
    requestAssume:Check(function(teleportBuffer: number)
        return teleportBuffer and true or false
    end)
    requestAssume:Run(function()
        task.spawn(function()
            ZoneController.transitionToZone(roomZone, function()
                -- Wait for Response
                local teleportBuffer = requestAssume:Await()
                if teleportBuffer then
                    -- Wait for teleport
                    local validationFinishedOffset = requestAssume:GetValidationFinishTimeframe()
                    task.wait(math.max(0, teleportBuffer - validationFinishedOffset))
                end
            end, function()
                local teleportBuffer = requestAssume:Await()
                return teleportBuffer and true or false
            end)

            -- Finished
            isRunningTeleportToRoomRequest = false
        end)
    end)

    return requestAssume
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
    local startTick = tick()
    while ZoneController.isZoneLoaded(zone) == false and (tick() - startTick < MAX_YIELD_TIME_ZONE_LOADING) do
        task.wait(WAIT_FOR_ZONE_TO_LOAD_INTERMISSION)
    end
    task.wait() -- Give client threads time to catch up
end

-------------------------------------------------------------------------------
-- Logic
-------------------------------------------------------------------------------

-- Communication
do
    Remotes.bindEvents({
        ZoneTeleport = function(zoneType: string, zoneId: string, teleportBuffer: number)
            ZoneController.teleportingToZoneIn(ZoneUtil.zone(zoneType, zoneId), teleportBuffer)
        end,
    })
end

return ZoneController
