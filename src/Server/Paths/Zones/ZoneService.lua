local ZoneService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local Signal = require(Paths.Shared.Signal)
local PlayerService = require(Paths.Server.PlayerService)

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
        ZoneId = playerZoneState.Room.Id,
    }

    return zone, playerZoneState.Room.Metadata
end

-- Returns Zone, Metadata (or nil)
function ZoneService.getPlayerMinigame(player: Player)
    local playerZoneState = ZoneService.getPlayerZoneState(player)
    if playerZoneState.Minigame.Id then
        local zone: ZoneConstants.Zone = {
            ZoneType = ZoneConstants.ZoneType.Minigame,
            ZoneId = playerZoneState.Minigame.Id,
        }

        return zone, playerZoneState.Minigame.Metadata
    end

    return nil
end

function ZoneService.sendPlayerToZone(player: Player, zone: ZoneConstants.Zone)
    --todo
end

--[[
    Sends the player to a room - either the one passed, or the one currently stored in their PlayerZoneState
]]
function ZoneService.sendPlayerToRoom(player: Player, roomZone: ZoneConstants.Zone?)
    roomZone = roomZone or ZoneService.getPlayerRoom(player)

    -- RETURN: Already there!
    local currentZone = ZoneService.getPlayerZone(player)
    if currentZone.ZoneType == roomZone.ZoneType and currentZone.ZoneId == roomZone.ZoneId then
        return
    end

    ZoneService.sendPlayerToZone(player, roomZone)
end

--[[
    Sends the player to a minigame.

    Can pass an optional `fromRoomzone` if we want them to return to a different room than the one they were in before we sent them to the minigame
]]
function ZoneService.sendPlayerToMinigame(player: Player, minigameZone: ZoneConstants.Zone, fromRoomZone: ZoneConstants.Zone?)
    minigameZone = minigameZone or ZoneService.getPlayerMinigame(player)

    -- RETURN: Already there!
    local currentZone = ZoneService.getPlayerZone(player)
    if currentZone.ZoneType == minigameZone.ZoneType and currentZone.ZoneId == minigameZone.ZoneId then
        return
    end

    ZoneService.sendPlayerToZone(player, minigameZone)

    -- EDGE CASE: Update room zone
    if fromRoomZone then
        local playerZoneState = ZoneService.getPlayerZoneState(player)
        playerZoneState.Room.Id = fromRoomZone.ZoneId
    end
end

function ZoneService.loadPlayer(player: Player)
    -- Setup Zone
    playerZoneStatesByPlayer[player] = TableUtil.deepClone(ZoneConstants.DefaultPlayerZoneState) :: ZoneConstants.PlayerZoneState

    -- Clear Cache
    PlayerService.getPlayerMaid(player):GiveTask(function()
        playerZoneStatesByPlayer[player] = nil
    end)
end

return ZoneService
