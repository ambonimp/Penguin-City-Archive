local ZoneController = {}

local ContentProvider = game:GetService("ContentProvider")
local Lighting = game:GetService("Lighting")
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
local PropertyStack = require(Paths.Shared.PropertyStack)
local WindController: typeof(require(Paths.Client.Zones.Cosmetics.Wind.WindController))
local Loader = require(Paths.Client.Loader)
local UIConstants = require(Paths.Client.UI.UIConstants)
local Scope = require(Paths.Shared.Scope)

local DEFAULT_ZONE_TELEPORT_DEBOUNCE = 5
local CHECK_SOS_DISTANCE_EVERY = 1
local SAVE_SOUL_AFTER_BEING_LOST_FOR = 1
local MIN_TIME_BETWEEN_SAVING = 5
local ZERO_VECTOR = Vector3.new(0, 0, 0)

local localPlayer = Players.LocalPlayer
local defaultZone = ZoneUtil.defaultZone()
local currentZone = defaultZone
local currentRoomZone = currentZone
local zoneMaid = Maid.new()
local isRunningTeleportToRoomRequest = false
local isTransitioningToZone = false
local onZoneUpdateMaid = Maid.new()
local transitionToZoneScope = Scope.new()

ZoneController.ZoneChanged = Signal.new() -- {fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone} Zone has officially changed

function ZoneController.Init()
    WindController = require(Paths.Client.Zones.Cosmetics.Wind.WindController)
end

function ZoneController.Start()
    -- SOS if we go too far from the zone
    task.spawn(function()
        local beenLostSinceTick: number | nil
        local lastSaveAtTick = 0
        while task.wait(CHECK_SOS_DISTANCE_EVERY) do
            -- RETURN: No character!
            local character = localPlayer.Character
            if not character then
                return
            end

            -- RETURN: No zone model?
            local zoneModel = ZoneUtil.getZoneModel(currentZone)
            if not zoneModel then
                return
            end

            local distance = (character:GetPivot().Position - zoneModel:GetPivot().Position).Magnitude
            local isLost = distance > ZoneConstants.StreamingTargetRadius
            if isLost then
                beenLostSinceTick = beenLostSinceTick or tick()
                local beenLostFor = tick() - beenLostSinceTick
                local timeSinceLastSave = tick() - lastSaveAtTick
                if beenLostFor >= SAVE_SOUL_AFTER_BEING_LOST_FOR and timeSinceLastSave >= MIN_TIME_BETWEEN_SAVING then
                    -- Save Our Soul!
                    lastSaveAtTick = tick()
                    ZoneController.teleportToDefaultZone()
                end
            else
                beenLostSinceTick = nil
            end
        end
    end)

    --[[
        onZoneUpdate Cosmetics

        Every time we enter a zone, any Cosmetics module that has a `.onZoneUpdate(maid)` method is invoked.
    ]]
    local function onZoneUpdate()
        onZoneUpdateMaid:Cleanup()

        local zoneModel = ZoneUtil.getZoneModel(currentZone)
        for _, descendant in pairs(Paths.Client.Zones.Cosmetics:GetDescendants()) do
            if descendant:IsA("ModuleScript") then
                local module = require(descendant)
                local onZoneUpdateCallback = typeof(module) == "table" and module.onZoneUpdate
                if onZoneUpdateCallback then
                    onZoneUpdateCallback(onZoneUpdateMaid, currentZone, zoneModel)
                end
            end
        end
    end

    ZoneController.ZoneChanged:Connect(onZoneUpdate)
    onZoneUpdate()
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

local function setupTeleporter(teleporter: BasePart, zoneCategory: string)
    local zoneType = teleporter.Name
    local zone = ZoneUtil.zone(zoneCategory, zoneType)

    -- Teleporter
    do
        local teleporterHitbox = PlayersHitbox.new():AddPart(teleporter)
        zoneMaid:GiveTask(teleporterHitbox)

        teleporterHitbox.PlayerEntered:Connect(function(player: Player)
            -- RETURN: Not local player
            if player ~= Players.LocalPlayer then
                return
            end

            if zone.ZoneCategory == ZoneConstants.ZoneCategory.Room then
                ZoneController.teleportToRoomRequest(zone)
            else
                warn(("%s wat"):format(zone.ZoneCategory))
            end
        end)
    end
end

local function setupTeleporters()
    for _, zoneCategory in pairs(ZoneConstants.ZoneCategory) do
        local departures = ZoneUtil.getDepartures(currentZone, zoneCategory)
        if departures then
            for _, teleporter: BasePart in pairs(departures:GetChildren()) do
                setupTeleporter(teleporter, zoneCategory)
            end
            zoneMaid:GiveTask(departures.ChildAdded:Connect(function(child)
                setupTeleporter(child, zoneCategory)
            end))
        end
    end
end

function ZoneController.checkIfTeleporting()
    return isTransitioningToZone or isRunningTeleportToRoomRequest
end

--[[
    Centralised logic for playing a transition, and consequently teleporting the character - with the option for it to be cancelled!
    - `teleportResult`: If true, good to go ahead with the teleport. False, abort. Expect it to yield!

    Yields until everything is done.
]]
function ZoneController.transitionToZone(
    toZone: ZoneConstants.Zone,
    teleportResult: () -> (boolean, CFrame?),
    blinkOptions: (Transitions.BlinkOptions)?
)
    -- Circular Dependencies
    local UIController = require(Paths.Client.UI.UIController)

    -- Init variables
    isTransitioningToZone = true
    transitionToZoneScope:NewScope()
    local thisScopeId = transitionToZoneScope:GetId()

    -- Ensure player is not sitting
    local character = Players.LocalPlayer.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local seatPart = humanoid and humanoid.SeatPart :: Seat
    if seatPart then
        humanoid.Sit = false
    end

    -- Populate blink options
    blinkOptions = blinkOptions or {}
    blinkOptions.DoAlignCamera = BooleanUtil.returnFirstBoolean(blinkOptions.DoAlignCamera, true)

    local function resetCharacter(toCFrame: CFrame?)
        if toCFrame then
            character:PivotTo(toCFrame)
        end

        CharacterUtil.unanchor(character)
    end

    -- Blink!
    Transitions.blink(function()
        -- RETURN: Teleport was cancelled
        local canTeleport, newCharacterCFrame = teleportResult()
        if not (canTeleport and newCharacterCFrame) then
            return
        end

        -- RETURN: No character?
        if not character then
            return
        end

        -- Impromptu character teleport/setup
        local oldCharacterCFrame = character:GetPivot()
        character:PivotTo(newCharacterCFrame)
        character.PrimaryPart.AssemblyLinearVelocity = ZERO_VECTOR
        CharacterUtil.anchor(character)

        -- YIELD: Wait for zone to load (possible RETURN if not loaded)
        local didLoad = ZoneController.waitForZoneToLoad(toZone)
        if not didLoad then
            warn("Zone Loading Timed Out")
            resetCharacter(oldCharacterCFrame)
            return
        end

        -- RETURN: Old scope
        if not transitionToZoneScope:Matches(thisScopeId) then
            resetCharacter(oldCharacterCFrame)
            return
        end

        -- Remove "zone-locked" states
        for _, uiState in pairs(UIConstants.RemoveStatesOnZoneTeleport) do
            UIController.getStateMachine():Remove(uiState)
        end

        -- Run Arrival Logic
        do
            -- Clean up old zone
            zoneMaid:Cleanup()

            -- Init zone variables
            local oldZone = currentZone
            currentZone = toZone
            if currentZone.ZoneCategory == ZoneConstants.ZoneCategory.Room then
                currentRoomZone = currentZone
            end

            -- Zone Settings
            ZoneController.applySettings(toZone)
            zoneMaid:GiveTask(function()
                ZoneController.revertSettings(toZone)
            end)

            -- Character
            resetCharacter()

            -- Setup
            setupTeleporters()

            -- Inform Client
            ZoneController.ZoneChanged:Fire(oldZone, toZone)
        end
    end, blinkOptions)

    if transitionToZoneScope:Matches(thisScopeId) then
        isTransitioningToZone = false
    end
end

-------------------------------------------------------------------------------
-- Teleports
-------------------------------------------------------------------------------

-- Returns our Assume object
function ZoneController.teleportToRoomRequest(roomZone: ZoneConstants.Zone)
    -- RETURN: Already requesting
    if isRunningTeleportToRoomRequest then
        warn("Already running a teleportToRoomRequest!")
        return
    end
    isRunningTeleportToRoomRequest = true

    -- ERROR: Not a room!
    if roomZone.ZoneCategory ~= ZoneConstants.ZoneCategory.Room then
        error("Not passed a room zone!")
    end

    -- Request Assume
    local requestAssume = Assume.new(function()
        return Remotes.invokeServer("RoomZoneTeleportRequest", roomZone.ZoneCategory, roomZone.ZoneType)
    end)
    requestAssume:Check(function(isAccepted: boolean?, _newCharacterCFrame: CFrame?)
        return isAccepted and true or false
    end)
    requestAssume:Run(function()
        task.spawn(function()
            ZoneController.transitionToZone(roomZone, function()
                -- Wait for Response
                local isAccepted, newCharacterCFrame = requestAssume:Await()
                return isAccepted and true or false, newCharacterCFrame
            end) -- Yields

            -- Stop yielding teleportToRoomRequest
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
    local zoneType = TableUtil.getRandom(ZoneConstants.ZoneType.Room)
    local roomZone = ZoneUtil.zone(ZoneConstants.ZoneCategory.Room, zoneType)
    ZoneController.teleportToRoomRequest(roomZone)
end

-------------------------------------------------------------------------------
-- Settings
-------------------------------------------------------------------------------

function ZoneController.applySettings(zone: ZoneConstants.Zone)
    local zoneSettings = ZoneUtil.getSettings(zone)
    if zoneSettings then
        local key = zone.ZoneCategory .. zone.ZoneType

        -- Lighting
        if zoneSettings.Lighting then
            PropertyStack.setProperties(Lighting, zoneSettings.Lighting, key)
        end

        -- Wind
        if zoneSettings.IsWindy then
            WindController.startWind()
        end
    end
end

function ZoneController.revertSettings(zone: ZoneConstants.Zone)
    local zoneSettings = ZoneUtil.getSettings(zone)
    if zoneSettings then
        local key = zone.ZoneCategory .. zone.ZoneType

        -- Lighting
        if zoneSettings.Lighting then
            PropertyStack.clearProperties(Lighting, zoneSettings.Lighting, key)
        end

        -- Wind
        if zoneSettings.IsWindy then
            WindController.stopWind()
        end
    end
end

-------------------------------------------------------------------------------
-- Loading
-------------------------------------------------------------------------------

function ZoneController.isZoneLoaded(zone: ZoneConstants.Zone)
    local zoneModel = ZoneUtil.getZoneModel(zone)
    return ZoneUtil.areAllBasePartsLoaded(zoneModel)
end

function ZoneController.waitForZoneToLoad(zone: ZoneConstants.Zone)
    local zoneModel = ZoneUtil.getZoneModel(zone)
    return ZoneUtil.waitForInstanceToLoad(zoneModel)
end

-------------------------------------------------------------------------------
-- Logic
-------------------------------------------------------------------------------

-- Communication
do
    Remotes.bindEvents({
        ZoneTeleport = function(zoneCategory: string, zoneType: string, zoneId: string?, newCharacterCFrame: CFrame)
            ZoneController.transitionToZone(ZoneUtil.zone(zoneCategory, zoneType, zoneId), function()
                return true, newCharacterCFrame
            end)
        end,
    })
end

-- Load Default Zone
Loader.giveTask("Zones", "DefaultZone", function()
    ContentProvider:PreloadAsync({ ZoneUtil.getZoneModel(ZoneUtil.defaultZone()) })
end)

return ZoneController
