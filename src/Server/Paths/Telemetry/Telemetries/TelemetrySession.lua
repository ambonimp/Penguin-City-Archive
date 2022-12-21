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
    for product, productData in pairs(productDatas) do
        if productData.TimeEquipped or productData.WasAcquired then
            local entry = {
                timeEquipped = productData.TimeEquipped and math.round(productData.TimeEquipped),
                dateFirstOwned = productData.WasAcquired and dateTime:FormatUniversalTime("YYYY-MM-DD", "en-us"),
            }

            local productTypeKey = StringUtil.toCamelCase(product.Type)
            local productIdKey = StringUtil.toCamelCase(product.Id)
            itemSummary[productTypeKey] = itemSummary[productTypeKey] or {}
            itemSummary[productTypeKey][productIdKey] = entry
        end
    end

    return itemSummary
end

local function getStampSummary(session: Session.Session)
    local dateTime = DateTime.now()

    local acquiredStamps = session:GetAcquiredStamps()
    local stampSummary = {}
    for stamp, stampTier in pairs(acquiredStamps) do
        local entry = {
            dateAchieved = dateTime:FormatUniversalTime("YYYY-MM-DD", "en-us"),
            tier = stamp.IsTiered and stampTier,
        }

        local stampTypeKey = StringUtil.toCamelCase(stamp.Type)
        local stampIdKey = StringUtil.toCamelCase(("%s%s"):format(stamp.IsTiered and "tiered_" or "", stamp.Id))
        stampSummary[stampTypeKey] = stampSummary[stampTypeKey] or {}
        stampSummary[stampTypeKey][stampIdKey] = entry
    end

    return stampSummary
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
        stampSummary = getStampSummary(session),
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
