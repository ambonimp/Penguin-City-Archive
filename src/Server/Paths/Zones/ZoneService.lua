local ZoneService = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local Signal = require(Paths.Shared.Signal)
local PlayerService = require(Paths.Server.PlayerService)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local Remotes = require(Paths.Shared.Remotes)
local Output = require(Paths.Shared.Output)
local TypeUtil = require(Paths.Shared.Utils.TypeUtil)
local CharacterUtil = require(Paths.Shared.Utils.CharacterUtil)
local ZoneSetup = require(Paths.Server.Zones.ZoneSetup)

type TeleportData = {
    InvokedServerTime: number?,
}

local ETHEREAL_KEY_TELEPORTS = "ZoneService_Teleport"
local CHECK_CHARACTER_COLLISIONS_AFTER_TELEPORT_EVERY = 0.5
local DESTROY_CREATED_ZONE_AFTER = 1

local playerZoneStatesByPlayer: { [Player]: ZoneConstants.PlayerZoneState } = {}
local defaultZone = ZoneUtil.defaultZone()

ZoneService.ZoneChanged = Signal.new() -- {player: Player, fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone}
ZoneService.PlayerTeleported = Signal.new() -- {player: Player, fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone}

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
    if playerZoneState then
        local zone = playerZoneState.RoomZone
        if ZoneUtil.doesZoneExist(zone) then
            return zone
        end
    end

    return defaultZone
end

-- Returns Zone
function ZoneService.getPlayerMinigame(player: Player)
    local playerZoneState = ZoneService.getPlayerZoneState(player)
    if playerZoneState then
        local zone = playerZoneState.MinigameZone
        if ZoneUtil.doesZoneExist(zone) then
            return zone
        end
    end

    return nil
end

function ZoneService.getPlayersInZone(zone: ZoneConstants.Zone)
    local players: { Player } = {}
    for _, player in pairs(Players:GetPlayers()) do
        local playerZone = ZoneService.getPlayerZone(player)
        if ZoneUtil.zonesMatch(zone, playerZone) then
            table.insert(players, player)
        end
    end

    return players
end

-- Returns a function to remove this zone cleanly. Returns the zoneModel as a second parameter
function ZoneService.createZone(zone: ZoneConstants.Zone, zoneModelChildren: { Instance }, spawnpoint: BasePart)
    local zoneCategory = zone.ZoneCategory
    local zoneType = zone.ZoneType

    -- ERROR: Zone already exists
    local zoneCategoryDirectory = ZoneUtil.getZoneCategoryDirectory(zoneCategory)
    local existingZoneModel = zoneCategoryDirectory:FindFirstChild(zoneType)
    if existingZoneModel then
        error(("Zone %q %s already exists!"):format(zoneCategory, zoneType))
    end

    -- Model
    local zoneModel = Instance.new("Model")
    zoneModel.Name = ZoneUtil.getZoneName(zone)
    zoneModel.Parent = zoneCategoryDirectory

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
            return
        end

        -- Teleport out any existing players
        for _, player in pairs(Players:GetPlayers()) do
            local playerZone = ZoneService.getPlayerZone(player)
            if ZoneUtil.zonesMatch(zone, playerZone) then
                -- Lets get 'em outta here!
                if zone.ZoneCategory == ZoneConstants.ZoneCategory.Minigame then
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
        zoneModel,
        function(newSpawn: BasePart)
            if spawnpoint then
                spawnpoint:Destroy()
            end
            spawnpoint = newSpawn
            spawnpoint.Name = "Spawnpoint"
            spawnpoint.Parent = zoneInstances
        end
end

--[[
    Returns teleportBuffer if successful (how many seconds until we pivot the players character to its destination)
    - `invokedServerTime` is used to help offset the TeleportBuffer if this was from a client request (rather than server)
]]
function ZoneService.teleportPlayerToZone(player: Player, zone: ZoneConstants.Zone, teleportData: TeleportData?)
    Output.doDebug(ZoneConstants.DoDebug, "teleportPlayerToZone", player, zone.ZoneCategory, zone.ZoneType, teleportData)

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
        warn(("No zone model for %s.%s"):format(zone.ZoneCategory, zone.ZoneType))
        return nil
    end

    -- WARN: No player zone state!
    local playerZoneState = ZoneService.getPlayerZoneState(player)
    if not playerZoneState then
        warn(("No player zone state for %q"):format(player.Name))
        return
    end

    -- Update State
    local oldZone = ZoneService.getPlayerZone(player)
    if zone.ZoneCategory == ZoneConstants.ZoneCategory.Room then
        playerZoneState.RoomZone = zone
        playerZoneState.MinigameZone = nil
    elseif zone.ZoneCategory == ZoneConstants.ZoneCategory.Minigame then
        -- Keep existing RoomType
        playerZoneState.MinigameZone = zone
    else
        warn(("Unknown zonetype %s"):format(zone.ZoneCategory))
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
            CharacterUtil.standOn(player.Character, spawnpoint, true)
            ZoneService.PlayerTeleported:Fire(player, oldZone, zone)

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
    Remotes.fireClient(player, "ZoneTeleport", zone.ZoneCategory, zone.ZoneType, zone.ZoneId, teleportBuffer)

    return teleportBuffer
end
Remotes.declareEvent("ZoneTeleport")

function ZoneService.loadPlayer(player: Player)
    Output.doDebug(ZoneConstants.DoDebug, "loadPlayer", player)

    -- Setup Zone
    playerZoneStatesByPlayer[player] = {
        RoomZone = defaultZone,
        TotalTeleports = 0,
    }

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
        RoomZoneTeleportRequest = function(player: Player, dirtyZoneCategory: any, dirtyZoneType: any, dirtyInvokedServerTime: any)
            -- Clean data
            local zoneCategory = TypeUtil.toString(dirtyZoneCategory)
            local zoneType = TypeUtil.toString(dirtyZoneType)
            local invokedServerTime = TypeUtil.toNumber(dirtyInvokedServerTime)

            -- RETURN: Bad data
            if not (zoneCategory and zoneType and invokedServerTime) then
                return
            end

            -- RETURN: Bad Zone
            local zone = ZoneUtil.zone(zoneCategory, zoneType)
            if not ZoneUtil.doesZoneExist(zone) then
                return nil
            end

            -- RETURN: Bad invokedServerTime
            if not invokedServerTime then
                return nil
            end

            return ZoneService.teleportPlayerToZone(player, zone, {
                InvokedServerTime = invokedServerTime,
            })
        end,
    })
end

-- See Cmdr TeleportServer
Remotes.declareEvent("CmdrRoomTeleport")

return ZoneService
