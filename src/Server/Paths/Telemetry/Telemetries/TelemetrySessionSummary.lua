local TelemetrySessionSummary = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local TelemetryService = require(Paths.Server.Telemetry.TelemetryService)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local MinigameSession = require(Paths.Server.Minigames.MinigameSession)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local SessionService = require(Paths.Server.SessionService)
local CurrencyService = require(Paths.Server.CurrencyService)
local Session = require(Paths.Shared.Session)

local function getZoneSummary(session: Session.Session)
    local zoneDatas = session:GetZoneData()
    local zoneSummary = {}
    for zoneString, zoneData in pairs(zoneDatas) do
        zoneSummary[zoneString] = {
            timeSpent = math.round(zoneData.TimeSpentSeconds),
            visitFrequency = zoneData.VisitCount,
        }
    end

    return zoneSummary
end

TelemetryService.unloadPlayer = function(player: Player)
    -- WARN: No session?
    local session = SessionService.getSession(player)
    if not session then
        warn(("No session for %s?"):format(player.Name))
        return
    end

    TelemetryService.postPlayerEvent(player, "sessionSummary", {
        sessionTime = math.round(session:GetPlayTime()),
        minigameTime = math.round(session:GetMinigameTimeSeconds()),
        coinsBankroll = CurrencyService.getCoins(player),
        zoneSummary = getZoneSummary(session),
    })
end

return TelemetrySessionSummary
