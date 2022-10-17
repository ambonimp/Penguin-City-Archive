local Paths = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local PathsUtil = require(Shared.Utils.PathsUtil)

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
Paths.Assets = ReplicatedStorage.Assets
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
        require(client.UI.Scaling.UIScaleController),
        require(client.CameraController),
        require(client.HousingController),
        require(client.DataController),
        require(client.Character.CharacterController),
        require(client.VehicleController),
        require(client.Input.InputController),
        require(client.Minigames.MinigameController),
        require(client.UI.CoreGui),
        require(client.CurrencyController),
        require(client.ZoneController),
        require(client.PlayerMenuController),

        -- UnitTest
        require(client.UnitTestingController),
    }

    PathsUtil.runInitAndStart(requiredModulesInOrder)
end)

-- Detect deprecated framework usage
Paths.__index = function(_, index)
    if index == "Shared" then
        error("Paths.Shared is deprecated! Use (1) Paths.Shared (2) Paths.Packages (3) Paths.Client")
    end
end

return Paths
