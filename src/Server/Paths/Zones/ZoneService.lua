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

local ETHEREAL_KEY_TELEPORTS = "ZoneService_Teleport"
local CHECK_CHARACTER_COLLISIONS_AFTER_TELEPORT_EVERY = 0.5
local DESTROY_CREATED_ZONE_AFTER = 1
local HAS_TELEPORTED_DISTANCE_EPISLON = 50
local REQUEST_STREAM_ASYNC_COUNT = 3

local playerZoneStatesByPlayer: { [Player]: ZoneConstants.PlayerZoneState } = {}
local defaultZone = ZoneUtil.defaultZone()

ZoneService.ZoneChanged = Signal.new() -- {player: Player, fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone, teleportData: ZoneConstants.TeleportData}

function ZoneService.Start()
    -- Setup Cosmetics
    for _, moduleScript: ModuleScript in pairs(Paths.Server.Zones.Cosmetics:GetDescendants()) do
        if moduleScript:IsA("ModuleScript") then
            local module = require(moduleScript)
            local zoneSetup = typeof(module) == "table" and module.zoneSetup
            if zoneSetup then
                zoneSetup()
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
                    ZoneService.teleportPlayerToZone(player, ZoneService.getPlayerRoom(player), {
                        TravelMethod = ZoneConstants.TravelMethod.ZoneDestroyed,
                    })
                else
                    ZoneService.teleportPlayerToZone(player, defaultZone, {
                        TravelMethod = ZoneConstants.TravelMethod.ZoneDestroyed,
                    })
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

    Success returns:
    - `true`: boolean
    - `characterCFrame`: CFrame, where the character is being pivoted to
    - `characterPivotedSignal`: Signal, fired when the server is informed that the client has pivoted their character

    Failure returns:
    - `false`: boolean
]]
function ZoneService.teleportPlayerToZone(player: Player, zone: ZoneConstants.Zone, teleportData: ZoneConstants.TeleportData)
    Output.doDebug(ZoneConstants.DoDebug, "ZoneService.teleportPlayerToZone", player, zone.ZoneCategory, zone.ZoneType, teleportData)

    -- Read Data
    teleportData = teleportData or {}
    local isClientRequest = teleportData.IsClientRequest
    local ignoreFromZone = teleportData.IgnoreFromZone

    -- WARN: No character!
    local character = player.Character
    if not character then
        warn(("%s has no Character!"):format(player.Name))
        return false
    end

    -- WARN: No zone model!
    local zoneModel = ZoneUtil.getZoneModel(zone)
    if not zoneModel then
        warn(("No zone model for %s.%s"):format(zone.ZoneCategory, zone.ZoneType))
        return false
    end

    -- WARN: No player zone state!
    local playerZoneState = ZoneService.getPlayerZoneState(player)
    if not playerZoneState then
        warn(("No player zone state for %q"):format(player.Name))
        return false
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
        return false
    end
    playerZoneState.TotalTeleports += 1

    -- Get spawnpoint + content Streaming
    local spawnpoint = ignoreFromZone and ZoneUtil.getZoneInstances(zone).Spawnpoint or ZoneUtil.getSpawnpoint(oldZone, zone)
    player:RequestStreamAroundAsync(spawnpoint.Position)
    if not player:IsDescendantOf(Players) then
        return
    end

    local newCharacterCFrame = CharacterUtil.getStandOnCFrame(character, spawnpoint, true)
    Output.doDebug(ZoneConstants.DoDebug, "ZoneService.teleportPlayerToZone", "requested streaming")

    -- Request stream async a few more times for best loading possible
    --[[     task.defer(function()
        for _ = 2, REQUEST_STREAM_ASYNC_COUNT do
            task.wait(1)
            player:RequestStreamAroundAsync(spawnpoint.Position)
        end
    end) *]]

    -- Signal for server detecting when character has been pivoted
    local characterPivotedSignal = Signal.new()

    -- Teleport player + manage character (after a delay) (as long as we're still on the same request)
    local cachedTotalTeleports = playerZoneState.TotalTeleports
    task.defer(function()
        if cachedTotalTeleports == playerZoneState.TotalTeleports then
            -- Disable Collisions
            CharacterUtil.setEthereal(player, true, ETHEREAL_KEY_TELEPORTS)
            Output.doDebug(ZoneConstants.DoDebug, "ZoneService.teleportPlayerToZone", player, "disable collisions")

            -- Yield until we have teleported
            while character and cachedTotalTeleports == playerZoneState.TotalTeleports do
                local distance = (character:GetPivot().Position - newCharacterCFrame.Position).Magnitude
                local hasTeleported = distance <= HAS_TELEPORTED_DISTANCE_EPISLON
                if hasTeleported then
                    break
                end

                task.wait()
            end

            -- Inform
            characterPivotedSignal:Fire()

            -- Wait to re-enable collisions (while we're still on the same request!)
            local zoneSettings = ZoneUtil.getSettings(zone)
            local collisionsAreDisabled = zoneSettings and zoneSettings.DisableCollisions
            if not collisionsAreDisabled then
                while cachedTotalTeleports == playerZoneState.TotalTeleports do
                    task.wait(CHECK_CHARACTER_COLLISIONS_AFTER_TELEPORT_EVERY)
                    if not (player.Character and CharacterUtil.isCollidingWithOtherCharacter(player.Character)) then
                        CharacterUtil.setEthereal(player, false, ETHEREAL_KEY_TELEPORTS)
                        Output.doDebug(ZoneConstants.DoDebug, "ZoneService.teleportPlayerToZone", player, "reenable collisions")
                        break
                    end
                end
            end
        end
    end)

    -- Inform Server
    ZoneService.ZoneChanged:Fire(player, oldZone, zone, teleportData)

    if not isClientRequest then
        -- Inform Client
        Remotes.fireClient(player, "ZoneTeleport", zone.ZoneCategory, zone.ZoneType, zone.ZoneId, newCharacterCFrame)
    end

    return true, newCharacterCFrame, characterPivotedSignal
end
Remotes.declareEvent("ZoneTeleport")

function ZoneService.loadPlayer(player: Player)
    Output.doDebug(ZoneConstants.DoDebug, "loadPlayer", player)

    -- Setup Zone
    playerZoneStatesByPlayer[player] = {
        RoomZone = defaultZone,
        TotalTeleports = 0,
    }

    -- Functions yields and we don't want it to prevent unloading
    task.spawn(function()
        -- Send to zone
        ZoneService.teleportPlayerToZone(player, ZoneService.getPlayerZone(player), {
            IsInitialTeleport = true,
        })
    end)

    -- Clear Cache
    PlayerService.getPlayerMaid(player):GiveTask(function()
        playerZoneStatesByPlayer[player] = nil
    end)
end

-- Communcation
do
    Remotes.bindFunctions({
        RoomZoneTeleportRequest = function(player: Player, dirtyZoneCategory: any, dirtyZoneType: any, dirtyTeleportData: any)
            -- Clean data
            local zoneCategory = TypeUtil.toString(dirtyZoneCategory)
            local zoneType = TypeUtil.toString(dirtyZoneType)

            -- RETURN: Bad data
            if not (zoneCategory and zoneType) then
                return
            end

            -- Scrub teleport data; easier to scrub rather than reject a bad table
            dirtyTeleportData = typeof(dirtyTeleportData) == "table" and dirtyTeleportData or {}
            local teleportData: ZoneConstants.TeleportData = {}
            if teleportData then
                teleportData.IsClientRequest = true
                teleportData.IgnoreFromZone = TypeUtil.toBoolean(dirtyTeleportData.IgnoreFromZone)
                teleportData.IsInitialTeleport = false
                teleportData.TravelMethod = ZoneConstants.TravelMethod[TypeUtil.toString(dirtyTeleportData.TravelMethod)]
            end

            -- RETURN: Bad Zone
            local zone = ZoneUtil.zone(zoneCategory, zoneType)
            if not ZoneUtil.doesZoneExist(zone) then
                return nil
            end

            Output.doDebug(ZoneConstants.DoDebug, "ZoneService", "RoomZoneTeleportRequest", player, zoneCategory, zoneType, teleportData)

            return ZoneService.teleportPlayerToZone(player, zone, teleportData)
        end,
    })
end

return ZoneService
