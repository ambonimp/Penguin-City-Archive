local Paths = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local PathsUtil = require(Shared.Utils.PathsUtil)

-- File Directories
local shared = ReplicatedStorage.Shared
Paths.Shared = shared

local packages = ReplicatedStorage.Packages
Paths.Packages = packages

local server = script
Paths.Server = server

-- Misc
Paths.Initialized = false

-- Loading Coroutine
task.delay(0, function()
    -- Require necessary files
    local requiredModulesInOrder = {
        -- Systems
        require(server.PlayerData),
        require(server.PlayerLoader),
        require(server.AnalyticsTracking),
        require(server.Vehicles),
        require(server.Cmdr.CmdrService),
    }

    PathsUtil.runInitAndStart(requiredModulesInOrder)
end)

-- Detect deprecated framework usage
Paths.__index = function(_, index)
    if index == "Shared" then
        error("Paths.Shared is deprecated! Use (1) Paths.Shared (2) Paths.Packages (3) Paths.Server")
    end
end

return Paths
