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
        -- Developer -> Live
        require(server.CollisionsService),
        require(server.DeveloperToLive),

        -- Systems
        require(server.Data.DataService),
        require(server.AnalyticsTracking),
        require(server.VehicleService),
        require(server.Cmdr.CmdrService),
        require(server.Characters.CharacterItemService),
        require(server.PlayerService),
        require(server.Products.ProductProcessReceipt),
        require(server.Zones.ZoneService),
        require(server.Housing.PlotService),
        require(server.Pets.PetService),
        require(server.Stamps.StampService),
        require(server.TutorialService),
        require(server.Tools.ToolService),
        require(server.Products.ProductService),

        -- Client/Server Utils
        require(shared.Utils.TextFilterUtil),

        -- UnitTest
        require(server.UnitTestingService),
    }

    task.defer(PathsUtil.runInitAndStart, requiredModulesInOrder)
end)

-- Detect deprecated framework usage
Paths.__index = function(_, index)
    if index == "Shared" then
        error("Paths.Shared is deprecated! Use (1) Paths.Shared (2) Paths.Packages (3) Paths.Server")
    end
end

return Paths
