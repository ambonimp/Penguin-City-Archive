local AnalyticsTracking = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Paths = require(ServerScriptService.Paths)
local VoldexAnalytics = require(ServerStorage.VoldexAnalytics)
local Output = require(Paths.Shared.Output)
local GameConstants = require(Paths.Shared.Constants.GameConstants)
local AnalyticsEvents = require(script.AnalyticsEvents)

-------------------------------------------------------------------------------
-- EventHandler
-------------------------------------------------------------------------------

local eventHandler = Instance.new("BindableEvent")
eventHandler.Name = "EventHandler"
eventHandler.Parent = ServerStorage

--[[
    Fire analytics events here!
    - event: string (lowerCamelCase)
    - player: Player
    - payload: { [string]: any } (table keys lowerCamelCase)
]]
AnalyticsTracking.EventHandler = eventHandler

eventHandler.Event:Connect(function(event: string, player: Player, payload: table)
    local success, message = pcall(function()
        VoldexAnalytics:FireAnalyticsEvent(player, event, payload)
    end)

    if not success then
        Output.warn(message)
    end
end)

-------------------------------------------------------------------------------
-- VoldexAnalytics Setup
-------------------------------------------------------------------------------

VoldexAnalytics:SetGameTitle(GameConstants.GameName)

-- Register Events
local usedEventIds: { [number]: boolean } = {}
local usedEventNames: { [string]: boolean } = {}
for eventName, eventId in pairs(AnalyticsEvents) do
    -- ERROR: Out of range eventId
    if eventId < 100 or eventId > 900 then
        Output.error(("eventId %d (%s) is out of range! Event Ids must be in the range 100-900"):format(eventId, eventName))
    end

    -- ERROR: Duplicate eventId
    if usedEventIds[eventId] then
        Output.error(("Duplicate eventId %d (%s)"):format(eventId, eventName))
    end

    -- ERROR: Duplicate eventName
    if usedEventNames[eventName] then
        Output.error(("Duplicate eventName %s"):format(eventName))
    end

    VoldexAnalytics:RegisterEvent(eventName, eventId)
end

return AnalyticsTracking
