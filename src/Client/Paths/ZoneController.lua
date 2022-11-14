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
local Limiter = require(Paths.Shared.Limiter)
local TableUtil = require(Paths.Shared.Utils.TableUtil)

local MAX_YIELD_TIME_ZONE_LOADING = 10
local WAIT_FOR_ZONE_TO_LOAD_INTERMISSION = 1 -- How often to verify if all base parts are loaded
local DEFAULT_ZONE_TELEPORT_DEBOUNCE = 5

local localPlayer = Players.LocalPlayer
local defaultZone = ZoneUtil.zone(ZoneConstants.ZoneType.Room, ZoneConstants.DefaultPlayerZoneState.RoomId)
local currentZone = defaultZone
local currentRoomZone = currentZone
local zoneMaid = Maid.new()
local isRunningTeleportToRoomRequest = false
local isPlayingTransition = false

ZoneController.ZoneChanging = Signal.new() -- {fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone} Zone is changing, but not confirmed
ZoneController.ZoneChanged = Signal.new() -- {fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone} Zone has officially changed

-------------------------------------------------------------------------------
-- Getters
-------------------------------------------------------------------------------

function ZoneController.getCurrentZone()
    return currentZone
end

function ZoneController.getCurrentRoomZone()
    return currentRoomZone
end

-- Returns the local players' house zone
function ZoneController.getLocalHouseInteriorZone()
    return ZoneUtil.houseInteriorZone(Players.LocalPlayer)
end

-- Returns true if the local player has edit perms
function ZoneController.hasEditPerms(houseOwner: Player)
    if houseOwner == Players.LocalPlayer then
        return true
    end

    --TODO Check DataController for list of UserId we have edit perms for
    return false
end

-------------------------------------------------------------------------------
-- Arrivals
-------------------------------------------------------------------------------

local function setupTeleporter(teleporter: BasePart, zoneType: string)
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
                -- TODO: SinglePlayerMinigameController.play(zone.ZoneId)
            else
                warn(("%s wat"):format(zone.ZoneType))
            end
        end)
    end
end

local function setupTeleporters()
    for _, zoneType in pairs(ZoneConstants.ZoneType) do
        local departures = ZoneUtil.getDepartures(currentZone, zoneType)
        if departures then
            for _, teleporter: BasePart in pairs(departures:GetChildren()) do
                setupTeleporter(teleporter, zoneType)
            end
            zoneMaid:GiveTask(departures.ChildAdded:Connect(function(child)
                setupTeleporter(child, zoneType)
            end))
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
    ZoneController.ZoneChanging:Fire(currentZone, toZone)

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
        else
            -- Was cancelled
            ZoneController.ZoneChanged:Fire(currentZone, currentZone)
        end
    end, blinkOptions)

    isPlayingTransition = false
end

function ZoneController.arrivedAtZone(zone: ZoneConstants.Zone)
    Output.doDebug(ZoneConstants.DoDebug, "arrivedAtZone", zone.ZoneType, zone.ZoneId)

    -- Clean up old zone
    zoneMaid:Cleanup()

    -- Init new Zone
    local oldZone = currentZone
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
    ZoneController.ZoneChanged:Fire(oldZone, currentZone)
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

function ZoneController.teleportToDefaultZone()
    -- RETURN: Debounce
    if not Limiter.debounce("ZoneController", "DefaultZoneTeleport", DEFAULT_ZONE_TELEPORT_DEBOUNCE) then
        return
    end

    ZoneController.teleportToRoomRequest(defaultZone)
end

function ZoneController.teleportToRandomRoom()
    local zoneId = TableUtil.getRandom(ZoneConstants.ZoneId.Room)
    local roomZone = ZoneUtil.zone(ZoneConstants.ZoneType.Room, zoneId)
    ZoneController.teleportToRoomRequest(roomZone)
end

-------------------------------------------------------------------------------
-- Loading
-------------------------------------------------------------------------------

function ZoneController.isZoneLoaded(zone: ZoneConstants.Zone)
    local zoneModel = ZoneUtil.getZoneModel(zone)

    -- Iterate through all instances, checking if all baseparts are loaded
    local instances = zoneModel:GetDescendants()
    table.insert(instances, zoneModel)

    for _, instance in pairs(instances) do
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
    local instances = zoneModel:GetDescendants()
    table.insert(instances, zoneModel)

    for _, instance in pairs(instances) do
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
