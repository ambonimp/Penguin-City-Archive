local Paths = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage.Shared
local PathsUtil = require(Modules.Utils.PathsUtil)

-- File Directories
local shared = ReplicatedStorage.Shared
Paths.Shared = shared

local packages = ReplicatedStorage.Packages
Paths.Packages = packages

local client = script
Paths.Client = client

-- Misc
Paths.UI = Players.LocalPlayer.PlayerGui
Paths.Templates = ReplicatedStorage.Templates
Paths.Initialized = false

-- Loading Coroutine
task.delay(0, function()
    -- Require necessary files
    local Loader = require(client.Loader)
    local requiredModulesInOrder = {
        -- Loader
        Loader,

        -- Systems
        require(client.Cmdr.CmdrController),
        require(client.UI.UIController),
        require(client.PlayerData),
        require(client.Character),
        require(client.Vehicles),

        -- UI
        require(client.UI.Screens.VehiclesScreen),
    }

    PathsUtil.runInitAndStart(requiredModulesInOrder)
end)

-- Detect deprecated framework usage
Paths.__index = function(_, index)
    if index == "Modules" then
        error("Paths.Modules is deprecated! Use (1) Paths.Shared (2) Paths.Packages (3) Paths.Client")
    end
end

return Paths
