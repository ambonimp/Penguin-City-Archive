--[[
    This is the brains of data/event reporting/posting in the Telemetry scope
]]
local TelemetryService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)

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
    warn(("Post Player Event %q %q"):format(player.Name, eventName), eventData)
end

return TelemetryService
