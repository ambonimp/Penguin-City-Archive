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

local function getItemSummary(session: Session.Session)
    local dateTime = DateTime.now()

    local productDatas = session:GetProductData()
    local itemSummary = {}
    for productType, productIdsDatas in pairs(productDatas) do
        local productIds = {}
        for productId, productData in pairs(productIdsDatas) do
            if productData.TimeEquipped or productData.WasPurchased then
                productIds[StringUtil.toCamelCase(productId)] = {
                    timeEquipped = productData.TimeEquipped and math.round(productData.TimeEquipped),
                    dateFirstOwned = productData.WasPurchased and dateTime:FormatUniversalTime("YYYY-MM-DD", "en-us"),
                }
            end
        end
        itemSummary[StringUtil.toCamelCase(productType)] = productIds
    end

    return itemSummary
end

-- sessionSummary
TelemetryService.addUnloadCallback(function(player: Player)
    -- WARN: No session?
    local session = SessionService.getSession(player) :: Session.Session
    if not session then
        warn(("No session for %s?"):format(player.Name))
        return
    end

    TelemetryService.postPlayerEvent(player, "sessionSummary", {
        sessionTime = math.round(session:GetPlayTime()),
        minigameTime = math.round(session:GetMinigameTimeSeconds()),
        coinsBankroll = CurrencyService.getCoins(player),
        zoneSummary = getZoneSummary(session),
        itemSummary = getItemSummary(session),
    })
end)

-- install
TelemetryService.addLoadCallback(function(player: Player)
    -- RETURN: Not first play session
    local totalPlaySessions = SessionService.getTotalPlaySessions(player)
    if totalPlaySessions > 1 then
        return
    end

    TelemetryService.postPlayerEvent(player, "install", {})
end)

-- firstSessionTime
TelemetryService.addUnloadCallback(function(player: Player)
    -- RETURN: Not first play session
    local totalPlaySessions = SessionService.getTotalPlaySessions(player)
    if totalPlaySessions > 1 then
        return
    end

    -- WARN: No session?
    local session = SessionService.getSession(player)
    if not session then
        warn(("No session for %s?"):format(player.Name))
        return
    end

    TelemetryService.postPlayerEvent(player, "firstSessionTime", {
        sessionLength = math.round(session:GetPlayTime()),
    })
end)

return TelemetrySessionSummary
