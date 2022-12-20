--[[
    Represents a player's play session
]]
local Session = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local ZoneUtil = require(ReplicatedStorage.Shared.Zones.ZoneUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

type ZoneData = {
    VisitCount: number,
    TimeSpentSeconds: number,
}

export type Session = typeof(Session.new())

function Session.new(player: Player)
    local session = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local startTick = tick()
    local minigameTimeSeconds = 0

    local zoneDataByZoneString: { [string]: ZoneData } = {}
    local currentZone: ZoneConstants.Zone | nil
    local lastZoneReportAtTick = 0

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function updateCurrentZone(zone: ZoneConstants.Zone)
        currentZone = zone
        lastZoneReportAtTick = tick()
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    -- Returns in seconds how long this player has been playing
    function session:GetPlayTime()
        return tick() - startTick
    end

    function session:AddMinigameTimeSeconds(addSeconds: number)
        minigameTimeSeconds += addSeconds
    end

    function session:GetMinigameTimeSeconds()
        return minigameTimeSeconds
    end

    function session:ReportZoneTeleport(fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone, teleportData: ZoneConstants.TeleportData)
        -- EDGE CASE: Initial teleport, begin population
        if teleportData.IsInitialTeleport then
            warn("initial teleport", toZone)
            updateCurrentZone(toZone)
            return
        end

        -- WARN: No current zone?
        if not currentZone then
            warn("No internal current zone.. initialising cache")
            updateCurrentZone(toZone)
            return
        end

        -- WARN: `fromZone` does not match current zone
        if not ZoneUtil.zonesMatch(fromZone, currentZone) then
            warn(
                ("Internal currentZone %q does not match fromZone %q"):format(
                    ZoneUtil.toString(player, currentZone),
                    ZoneUtil.toString(player, fromZone)
                )
            )
            updateCurrentZone(toZone)
        end

        -- Update current (aka now old) zone
        local zoneString = ZoneUtil.toString(player, currentZone)
        local zoneData: ZoneData = zoneDataByZoneString[zoneString]
            or {
                TimeSpentSeconds = 0,
                VisitCount = 0,
            }
        zoneDataByZoneString[zoneString] = zoneData

        zoneData.TimeSpentSeconds += (tick() - lastZoneReportAtTick)
        zoneData.VisitCount += 1

        updateCurrentZone(toZone)
    end

    function session:GetZoneData()
        local currentZoneDataByZoneString = TableUtil.deepClone(zoneDataByZoneString)

        -- We need to add the current playtime for the current zone..
        local currentZoneString = ZoneUtil.toString(player, currentZone)
        local zoneData: ZoneData = currentZoneDataByZoneString[currentZoneString]
            or {
                TimeSpentSeconds = 0,
                VisitCount = 0,
            }
        currentZoneDataByZoneString[currentZoneString] = zoneData

        zoneData.TimeSpentSeconds += (tick() - lastZoneReportAtTick)
        zoneData.VisitCount += 1

        return currentZoneDataByZoneString
    end

    return session
end

return Session
