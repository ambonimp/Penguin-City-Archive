local ZoneService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local Signal = require(Paths.Shared.Signal)
local PlayerService = require(Paths.Server.PlayerService)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)
local CharacterService = require(Paths.Server.CharacterService)
local Remotes = require(Paths.Shared.Remotes)
local Output = require(Paths.Shared.Output)
local PlotService = require(Paths.Server.PlotService)

local playerZoneStatesByPlayer: { [Player]: ZoneConstants.PlayerZoneState } = {}

ZoneService.ZoneChanged = Signal.new() -- {player: Player, fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone}

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

-- Returns Zone, Metadata
function ZoneService.getPlayerRoom(player: Player)
    local playerZoneState = ZoneService.getPlayerZoneState(player)
    local zone: ZoneConstants.Zone = {
        ZoneType = ZoneConstants.ZoneType.Room,
        ZoneId = playerZoneState.RoomId,
    }

    return zone
end

-- Returns Zone, Metadata (or nil)
function ZoneService.getPlayerMinigame(player: Player)
    local playerZoneState = ZoneService.getPlayerZoneState(player)
    if playerZoneState.MinigameId then
        local zone: ZoneConstants.Zone = {
            ZoneType = ZoneConstants.ZoneType.Minigame,
            ZoneId = playerZoneState.MinigameId,
        }

        return zone
    end

    return nil
end

--[[
    Returns true if successful
    - `invokedServerTime` is used to help offset the TeleportBuffer if this was from a client request (rather than server)
]]
function ZoneService.teleportPlayerToZone(player: Player, zone: ZoneConstants.Zone, invokedServerTime: number?, oldPlayer: Player?)
    Output.doDebug(ZoneConstants.DoDebug, "teleportPlayerToZone", player, zone.ZoneType, zone.ZoneId, invokedServerTime)

    invokedServerTime = invokedServerTime or game.Workspace:GetServerTimeNow()

    -- WARN: No character!
    if not player.Character then
        warn(("%s has no Character!"):format(player.Name))
        return false
    end

    -- Update State
    local oldZone = ZoneService.getPlayerZone(player)
    local playerZoneState = ZoneService.getPlayerZoneState(player)
    if zone.ZoneType == ZoneConstants.ZoneType.Room then
        playerZoneState.RoomId = zone.ZoneId
    elseif zone.ZoneType == ZoneConstants.ZoneType.Minigame then
        playerZoneState.MinigameId = zone.ZoneId
    else
        warn(("Unknown zonetype %s"):format(zone.ZoneType))
        return false
    end
    playerZoneState.TotalTeleports += 1

    -- Inform Server
    ZoneService.ZoneChanged:Fire(player, oldZone, zone)

    -- Content Streaming
    local spawnpoint = ZoneUtil.getSpawnpoint(oldZone, zone)
    player:RequestStreamAroundAsync(spawnpoint.Position)

    -- Teleport player (after a delay) (as long as we're still on the same request)
    local cachedTotalTeleports = playerZoneState.TotalTeleports
    local timeElapsedSinceInvoke = (game.Workspace:GetServerTimeNow() - invokedServerTime)
    local teleportBuffer = math.max(0, ZoneConstants.TeleportBuffer - timeElapsedSinceInvoke)
    task.delay(teleportBuffer, function()
        if cachedTotalTeleports == playerZoneState.TotalTeleports then
            if zone.ZoneId == "Start" and PlotService.PlayerHasPlot(oldPlayer or player, "House") then
                local interior = PlotService.PlayerHasPlot(oldPlayer or player, "House")
                CharacterService.standOn(player.Character, interior:FindFirstChildOfClass("Model").Spawn)
            elseif
                oldPlayer
                and zone.ZoneId == "Neighborhood"
                and PlotService.PlayerHasPlot(oldPlayer, "Plot")
                and oldZone.ZoneId == "Start"
            then
                local exterior = PlotService.PlayerHasPlot(oldPlayer, "Plot")
                CharacterService.standOn(player.Character, exterior:FindFirstChildOfClass("Model").Spawn)
            else
                CharacterService.standOn(player.Character, spawnpoint)
            end
        end
    end)

    -- Inform Client
    Remotes.fireClient(player, "ZoneChanged", zone.ZoneType, zone.ZoneId, teleportBuffer)
end
Remotes.declareEvent("ZoneChanged")

--[[
    Sends the player to a room - either the one passed, or the one currently stored in their PlayerZoneState
]]
function ZoneService.sendPlayerToRoom(player: Player, roomZone: ZoneConstants.Zone?)
    Output.doDebug(ZoneConstants.DoDebug, "sendPlayerToRoom", player, roomZone and roomZone.ZoneId)

    roomZone = roomZone or ZoneService.getPlayerRoom(player)

    -- RETURN: Already there!
    local currentZone = ZoneService.getPlayerZone(player)
    if currentZone.ZoneType == roomZone.ZoneType and currentZone.ZoneId == roomZone.ZoneId then
        return
    end

    ZoneService.teleportPlayerToZone(player, roomZone)
end

--[[
    Sends the player to a minigame.

    Can pass an optional `fromRoomzone` if we want them to return to a different room than the one they were in before we sent them to the minigame
]]
function ZoneService.sendPlayerToMinigame(player: Player, minigameZone: ZoneConstants.Zone, fromRoomZone: ZoneConstants.Zone?)
    Output.doDebug(ZoneConstants.DoDebug, "sendPlayerToMinigame", player, minigameZone.ZoneId, fromRoomZone and fromRoomZone.ZoneId)

    minigameZone = minigameZone or ZoneService.getPlayerMinigame(player)

    -- RETURN: Already there!
    local currentZone = ZoneService.getPlayerZone(player)
    if currentZone.ZoneType == minigameZone.ZoneType and currentZone.ZoneId == minigameZone.ZoneId then
        return
    end

    ZoneService.teleportPlayerToZone(player, minigameZone)

    -- EDGE CASE: Update room zone
    if fromRoomZone then
        local playerZoneState = ZoneService.getPlayerZoneState(player)
        playerZoneState.RoomId = fromRoomZone.ZoneId
    end
end

function ZoneService.loadPlayer(player: Player)
    Output.doDebug(ZoneConstants.DoDebug, "loadPlayer", player)

    -- Setup Zone
    playerZoneStatesByPlayer[player] = TableUtil.deepClone(ZoneConstants.DefaultPlayerZoneState) :: ZoneConstants.PlayerZoneState

    -- Send to zone
    ZoneService.teleportPlayerToZone(player, ZoneService.getPlayerZone(player), 0) -- invokedTime of 0 to immediately move the player Character

    -- Clear Cache
    PlayerService.getPlayerMaid(player):GiveTask(function()
        playerZoneStatesByPlayer[player] = nil
    end)
end

return ZoneService
