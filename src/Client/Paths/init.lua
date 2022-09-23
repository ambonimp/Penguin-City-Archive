local Paths = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage.Modules
local Packages = ReplicatedStorage.Packages
local PathsUtil = require(Modules.Utils.PathsUtil)

Paths.UI = Players.LocalPlayer.PlayerGui:WaitForChild("Interface")
Paths.Templates = ReplicatedStorage.Templates
Paths.Initialized = false

-- Curate Modules
-- `Modules` has intellisense + actual access to files under: Modules, Packages, Paths
local directories: { Instance } = { Modules, Packages, script }
local modules: (typeof(Modules) & typeof(Packages) & typeof(script)) | table = PathsUtil.createModules(directories)
Paths.Modules = modules

-- Loading Coroutine
task.delay(0, function()
    -- Require necessary files
    local Loader = require(modules.Loader)
    local requiredModulesInOrder = {
        -- Loader
        Loader,

        -- Systems
        require(modules.Cmdr.CmdrController),
        require(modules.PlayerData),
        require(modules.Character),
        require(modules.Vehicles),

        -- UI
        require(modules.UI.UIController), -- Load any UI Screens in here please!
        require(modules.UI.Screens.Vehicles.VehiclesUI),
    }

    PathsUtil.runInitAndStart(requiredModulesInOrder)
end)

return Paths
