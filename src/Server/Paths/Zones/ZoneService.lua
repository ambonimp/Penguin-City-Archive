local ZoneService = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local Signal = require(Paths.Shared.Signal)
local PlayerService = require(Paths.Server.PlayerService)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local CharacterService = require(Paths.Server.Characters.CharacterService)
local Remotes = require(Paths.Shared.Remotes)
local Output = require(Paths.Shared.Output)
local TypeUtil = require(Paths.Shared.Utils.TypeUtil)
local PlayersHitbox = require(Paths.Shared.PlayersHitbox)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local ZoneSetup = require(Paths.Server.Zones.ZoneSetup)

type TeleportData = {
    InvokedServerTime: number?,
}

local DEPARTURE_COLLISION_AREA_SIZE = Vector3.new(10, 2, 10)
local ETHEREAL_KEY_DEPARTURES = "ZoneService_Departure"
local ETHEREAL_KEY_TELEPORTS = "ZoneService_Teleport"
local CHECK_CHARACTER_COLLISIONS_AFTER_TELEPORT_EVERY = 0.5
local DESTROY_CREATED_ZONE_AFTER = 1

local playerZoneStatesByPlayer: { [Player]: ZoneConstants.PlayerZoneState } = {}
local defaultZone = ZoneUtil.zone(ZoneConstants.ZoneType.Room, ZoneConstants.DefaultPlayerZoneState.RoomId)

ZoneService.ZoneChanged = Signal.new() -- {player: Player, fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone}

function ZoneService.Init()
    -- Setup character collisions around departures
    local collisionDisablers = Instance.new("Folder")
    collisionDisablers.Name = "CollisionDisablers"
    collisionDisablers.Parent = game.Workspace

    for zoneType, zoneIds in pairs(ZoneConstants.ZoneId) do
        for zoneId, _ in pairs(zoneIds) do
            local zone = ZoneUtil.zone(zoneType, zoneId)
            local departures =
                { ZoneUtil.getDepartures(zone, ZoneConstants.ZoneType.Minigame), ZoneUtil.getDepartures(zone, ZoneConstants.ZoneType.Room) }
            for _, departureDirectory: Instance in pairs(departures) do
                for _, departurePart in pairs(departureDirectory:GetChildren()) do
                    -- Create collision changer
                    local collisionPart: BasePart = departurePart:Clone()
                    collisionPart.Name = ("%s_%s_%s_CollisionDisabler"):format(zoneType, zoneId, departurePart.Name)
                    collisionPart.Size = collisionPart.Size + DEPARTURE_COLLISION_AREA_SIZE
                    collisionPart.Parent = collisionDisablers

                    local collisionHitbox = PlayersHitbox.new():AddPart(collisionPart)
                    collisionHitbox.PlayerEntered:Connect(function(player)
                        CharacterUtil.setEthereal(player, true, ETHEREAL_KEY_DEPARTURES)
                    end)
                    collisionHitbox.PlayerLeft:Connect(function(player)
                        CharacterUtil.setEthereal(player, false, ETHEREAL_KEY_DEPARTURES)
                    end)
                end
            end
        end
    end
end

function ZoneService.getPlayerZoneState(player: Player)
    return playerZoneStatesByPlayer[player]
end

function ZoneService.getPlayerZone(player: Player)
    -- Curate specific zone
    local minigameZone: ZoneConstants.Zone, minigameMetadata = ZoneService.getPlayerMinigame(player)
    local roomZone, roomMetadata = ZoneService.getPlayerRoom(player)

    if minigameZone then
        return minigameZone, minigameMetadata
    end

    return roomZone, roomMetadata
end

-- Returns Zone
function ZoneService.getPlayerRoom(player: Player)
    local playerZoneState = ZoneService.getPlayerZoneState(player)
    return ZoneUtil.zone(ZoneConstants.ZoneType.Room, playerZoneState.RoomId)
end

-- Returns Zone
function ZoneService.getPlayerMinigame(player: Player)
    local playerZoneState = ZoneService.getPlayerZoneState(player)
    if playerZoneState.MinigameId then
        return ZoneUtil.zone(ZoneConstants.ZoneType.Minigame, playerZoneState.MinigameId)
    end

    return nil
end

-- Returns a function to remove this zone cleanly. Returns the zoneModel as a second parameter
function ZoneService.createZone(zoneType: string, zoneId: string, zoneModelChildren: { Instance }, spawnpoint: BasePart)
    -- ERROR: Zone already exists
    local zoneTypeDirectory = ZoneUtil.getZoneTypeDirectory(zoneType)
    local existingZoneModel = ZoneUtil.getZoneTypeDirectory(zoneType):FindFirstChild(zoneId)
    if existingZoneModel then
        error(("Zone %q %s already exists!"):format(zoneType, zoneId))
    end

    -- Create
    local zone = ZoneUtil.zone(zoneType, zoneId)

    -- Model
    local zoneModel = Instance.new("Model")
    zoneModel.Name = zoneId
    zoneModel.Parent = zoneTypeDirectory

    for _, child in pairs(zoneModelChildren) do
        child.Parent = zoneModel
    end

    -- Zone Instances
    local zoneInstances = Instance.new("Configuration")
    zoneInstances.Name = "ZoneInstances"
    zoneInstances.Parent = zoneModel

    for _, folderName in pairs(ZoneConstants.ZoneInstances.FolderNames) do
        local folder = Instance.new("Folder")
        folder.Name = folderName
        folder.Parent = zoneInstances
    end

    spawnpoint.Name = "Spawnpoint"
    spawnpoint.Parent = zoneInstances

    -- Setup
    ZoneSetup.setupCreatedZone(zoneModel)

    -- Return
    return function()
        -- RETURN: Already destroyed!
        if zoneModel.Parent == nil then
            warn("already destroyed")
            return
        end

        -- Teleport out any existing players
        for _, player in pairs(Players:GetPlayers()) do
            local playerZone = ZoneService.getPlayerZone(player)
            if ZoneUtil.zonesMatch(zone, playerZone) then
                -- Lets get 'em outta here!
                if zone.ZoneType == ZoneConstants.ZoneType.Minigame then
                    ZoneService.teleportPlayerToZone(player, ZoneService.getPlayerRoom(player))
                else
                    ZoneService.teleportPlayerToZone(player, defaultZone)
                end
            end
        end

        task.delay(DESTROY_CREATED_ZONE_AFTER, function()
            -- Delete model after client has had time to hide with transition
            zoneModel:Destroy()
        end)
    end,
        zoneModel
end

--[[
    Returns teleportBuffer if successful (how many seconds until we pivot the players character to its destination)
    - `invokedServerTime` is used to help offset the TeleportBuffer if this was from a client request (rather than server)
]]
function ZoneService.teleportPlayerToZone(player: Player, zone: ZoneConstants.Zone, teleportData: TeleportData?)
    Output.doDebug(ZoneConstants.DoDebug, "teleportPlayerToZone", player, zone.ZoneType, zone.ZoneId, teleportData)

    teleportData = teleportData or {}
    local invokedServerTime = teleportData.InvokedServerTime or game.Workspace:GetServerTimeNow()

    -- WARN: No character!
    if not player.Character then
        warn(("%s has no Character!"):format(player.Name))
        return nil
    end

    -- WARN: No zone model!
    local zoneModel = ZoneUtil.getZoneModel(zone)
    if not zoneModel then
        warn(("No zone model for %s.%s"):format(zone.ZoneType, zone.ZoneId))
        return nil
    end

    -- Update State
    local oldZone = ZoneService.getPlayerZone(player)
    local playerZoneState = ZoneService.getPlayerZoneState(player)
    if zone.ZoneType == ZoneConstants.ZoneType.Room then
        playerZoneState.RoomId = zone.ZoneId
        playerZoneState.MinigameId = nil
    elseif zone.ZoneType == ZoneConstants.ZoneType.Minigame then
        -- Keep existing RoomId
        playerZoneState.MinigameId = zone.ZoneId
    else
        warn(("Unknown zonetype %s"):format(zone.ZoneType))
        return nil
    end
    playerZoneState.TotalTeleports += 1

    -- Inform Server
    ZoneService.ZoneChanged:Fire(player, oldZone, zone)

    -- Get spawnpoint + content Streaming
    local spawnpoint = ZoneUtil.getSpawnpoint(oldZone, zone)
    player:RequestStreamAroundAsync(spawnpoint.Position)

    -- Teleport player + manage character (after a delay) (as long as we're still on the same request)
    local cachedTotalTeleports = playerZoneState.TotalTeleports
    local timeElapsedSinceInvoke = (game.Workspace:GetServerTimeNow() - invokedServerTime)
    local teleportBuffer = math.max(0, ZoneConstants.TeleportBuffer - timeElapsedSinceInvoke)
    task.delay(teleportBuffer, function()
        if cachedTotalTeleports == playerZoneState.TotalTeleports then
            -- Disable Collisions
            CharacterUtil.setEthereal(player, true, ETHEREAL_KEY_TELEPORTS)

            -- Teleport
            CharacterService.standOn(player.Character, spawnpoint, true)

            -- Wait to re-enable collisions (while we're still on the same request!)
            local zoneSettings = ZoneUtil.getSettings(zone)
            local collisionsAreDisabled = zoneSettings and zoneSettings.DisableCollisions
            if not collisionsAreDisabled then
                while cachedTotalTeleports == playerZoneState.TotalTeleports do
                    task.wait(CHECK_CHARACTER_COLLISIONS_AFTER_TELEPORT_EVERY)
                    if not (player.Character and CharacterUtil.isCollidingWithOtherCharacter(player.Character)) then
                        CharacterUtil.setEthereal(player, false, ETHEREAL_KEY_TELEPORTS)
                        break
                    end
                end
            end
        end
    end)

    -- Inform Client
    Remotes.fireClient(player, "ZoneTeleport", zone.ZoneType, zone.ZoneId, teleportBuffer)

    return teleportBuffer
end
Remotes.declareEvent("ZoneTeleport")

function ZoneService.loadPlayer(player: Player)
    Output.doDebug(ZoneConstants.DoDebug, "loadPlayer", player)

    -- Setup Zone
    playerZoneStatesByPlayer[player] = TableUtil.deepClone(ZoneConstants.DefaultPlayerZoneState) :: ZoneConstants.PlayerZoneState

    -- Send to zone
    ZoneService.teleportPlayerToZone(player, ZoneService.getPlayerZone(player), {
        InvokedServerTime = 0,
    }) -- invokedTime of 0 to immediately move the player Character

    -- Clear Cache
    PlayerService.getPlayerMaid(player):GiveTask(function()
        playerZoneStatesByPlayer[player] = nil
    end)
end

-- Communcation
do
    Remotes.bindFunctions({
        RoomZoneTeleportRequest = function(player: Player, dirtyZoneType: any, dirtyZoneId: any, dirtyInvokedServerTime: any)
            -- Clean data
            local zoneType = TypeUtil.toString(dirtyZoneType)
            local zoneId = TypeUtil.toString(dirtyZoneId)
            local invokedServerTime = TypeUtil.toNumber(dirtyInvokedServerTime)

            -- RETURN NIL: Bad Zone
            local isIglooZone = tonumber(zoneId) and Players:GetPlayerByUserId(tonumber(zoneId))
            local isStoredZone = ZoneConstants.ZoneType[zoneType] and ZoneConstants.ZoneId[zoneType][zoneId] and true or false
            if not (isStoredZone or isIglooZone) then
                return nil
            end

            -- RETURN NIL: Bad invokedServerTime
            if not invokedServerTime then
                return nil
            end

            local zone = ZoneUtil.zone(zoneType, zoneId)
            return ZoneService.teleportPlayerToZone(player, zone, {
                InvokedServerTime = invokedServerTime,
            })
        end,
    })
end

return ZoneService
