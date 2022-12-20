--[[
    This is the brains of data/event reporting/posting in the Telemetry scope
]]
local TelemetryService = {}

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Paths = require(ServerScriptService.Paths)
local VoldexAnalytics = require(ServerStorage.VoldexAnalytics)
local Output = require(Paths.Shared.Output)
local GameConstants = require(Paths.Shared.Constants.GameConstants)
local GameUtil = require(Paths.Shared.Utils.GameUtil)

--!! Be careful with changing any existing values!
-- https://docs.google.com/document/d/1GgXv97M3vKuzEhwAOloIaYwfWVWoJBdgZRtfC9u5US0/edit#
local EVENT_ID_BY_NAME = {
    sessionSummary = 100,
    currencySunk = 110,
    currencyInjected = 111,
    houseEdited = 120,
    miniGameSummary = 130,
    zoneTravel = 140,
}
local NATIVE_EVENTS_BY_NAME = {
    transactionCompleted = 3,
    install = 4,
    firstSessionTime = 6,
}

local eventHandler: BindableEvent

-------------------------------------------------------------------------------
-- Service + API
-------------------------------------------------------------------------------

function TelemetryService.Start()
    -- Loaded Telemetries
    do
        for _, descendant in pairs(Paths.Server.Telemetry.Telemetries:GetDescendants()) do
            if descendant:IsA("ModuleScript") then
                require(descendant)
            end
        end
    end
end

function TelemetryService.unloadPlayer(_player: Player) end -- Gets overwritten by TelemetrySessionSummary

--[[
    Wrapper for how we post an event
]]
function TelemetryService.postPlayerEvent(player: Player, eventName: string, eventData: table)
    -- ERROR: Non-registered event
    if not (EVENT_ID_BY_NAME[eventName] or NATIVE_EVENTS_BY_NAME[eventName]) then
        error(("EventName %q not registered to VoldexAnalytics"):format(eventName))
    end

    warn(("Posting Player Event %q %q"):format(player.Name, eventName), eventData)

    -- RETURN: Not on live game
    if not (GameUtil.isLiveGame() and not RunService:IsStudio()) then
        return
    end

    eventHandler:Fire(eventName, player, eventData)
end

-------------------------------------------------------------------------------
-- EventHandler
-------------------------------------------------------------------------------

eventHandler = Instance.new("BindableEvent")
eventHandler.Name = "EventHandler"
eventHandler.Parent = ServerStorage

--[[
    Fire analytics events here!
    - event: string (lowerCamelCase)
    - player: Player
    - payload: { [string]: any } (table keys lowerCamelCase)
]]
TelemetryService.EventHandler = eventHandler

eventHandler.Event:Connect(function(event: string, player: Player, payload: table)
    local success, message = pcall(function()
        VoldexAnalytics:FireAnalyticsEvent(player, event, payload)
    end)

    if not success then
        warn("Error on VoldexAnalytics:FireAnalyticsEvent: ", message)
    end
end)

-------------------------------------------------------------------------------
-- VoldexAnalytics Setup
-------------------------------------------------------------------------------

VoldexAnalytics:SetGameTitle(GameConstants.GameName)

-- Register Events
local usedEventIds: { [number]: boolean } = {}
for eventName, eventId in pairs(EVENT_ID_BY_NAME) do
    -- ERROR: Out of range eventId
    if eventId < 100 or eventId > 900 then
        Output.error(("eventId %d (%s) is out of range! Event Ids must be in the range 100-900"):format(eventId, eventName))
    end

    -- ERROR: Duplicate eventId
    if usedEventIds[eventId] then
        Output.error(("Duplicate eventId %d (%s)"):format(eventId, eventName))
    end

    VoldexAnalytics:RegisterEvent(eventName, eventId)
end

return TelemetryService
