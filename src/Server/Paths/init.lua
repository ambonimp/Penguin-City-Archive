local Paths = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage.Modules
local Packages = ReplicatedStorage.Packages
local PathsUtil = require(Modules.Utils.PathsUtil)

Paths.Initialized = false

-- Curate Modules
-- `Modules` has intellisense + actual access to files under: Modules, Packages, Paths
local directories: { Instance } = { Modules, Packages, script }
local modules: (typeof(Modules) & typeof(Packages) & typeof(script)) | table = PathsUtil.createModules(directories)
Paths.Modules = modules

-- Loading Coroutine
task.delay(0, function()
    -- Require necessary files
    local requiredModulesInOrder = {
        -- Systems
        require(modules.PlayerData),
        require(modules.PlayerLoader),
        require(modules.AnalyticsTracking),
        require(modules.Vehicles),
        require(modules.Cmdr.CmdrService),
    }

    PathsUtil.runInitAndStart(requiredModulesInOrder)
end)

return Paths
