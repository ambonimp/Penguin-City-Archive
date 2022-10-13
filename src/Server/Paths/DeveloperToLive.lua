--[[
    Runs any necessary logic to convert game state from "developer" to "live" before any other routines get running.

    There may be logic elsewhere that needs a "developer to live" routine, but is happy in its own scope
]]
local DeveloperToLive = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)

-- Zones
do
    require(Paths.Server.Zones.ZoneSetup).setup()
end

return DeveloperToLive
