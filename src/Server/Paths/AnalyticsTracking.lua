local AnalyticsTracking = {}

local ServerStorage = game:GetService("ServerStorage")
local VoldexAnalytics = require(ServerStorage.VoldexAnalytics)

local eventHandler = Instance.new("BindableEvent")
eventHandler.Name = "EventHandler"
eventHandler.Parent = ServerStorage

VoldexAnalytics:SetGameTitle("penguin-city")
eventHandler.Event:Connect(function(event, player, payload)
    local success, message = pcall(function()
        VoldexAnalytics:FireAnalyticsEvent(player, event, payload)
    end)

    if not success then
        warn(message)
    end
end)

return AnalyticsTracking
