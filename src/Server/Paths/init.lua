local Paths = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules
local Packages = ReplicatedStorage.Packages
local Constants = Shared.Constants

Paths.Modules = {}
Paths.Initialized = false

-- Init Modules
do
    -- Constants
    Paths.Modules["GameConstants"] = require(Constants.GameConstants)
    Paths.Modules["VehicleConstants"] = require(Constants.VehicleConstants)

    -- Packages
    Paths.Modules["Promise"] = require(Packages.promise)
    Paths.Modules["Maid"] = require(Packages.maid)

    -- Shared
    Paths.Modules["Remotes"] = require(Shared.Remotes)
    Paths.Modules["Signal"] = require(Shared.Signal)

    -- Utils
    Paths.Modules["TableUtil"] = require(Shared.Utils.TableUtil)
    Paths.Modules["DataUtil"] = require(Shared.Utils.DataUtil)
    Paths.Modules["InteractionUtil"] = require(Shared.Utils.InteractionUtil)
    Paths.Modules["VehicleUtil"] = require(Shared.Utils.VehicleUtil)

    --
    Paths.Modules["PlayerData"] = require(script.PlayerData)
    Paths.Modules["AnalyticsTracking"] = require(script.AnalyticsTracking)
    Paths.Modules["PlayerLoader"] = require(script.PlayerLoader)
    Paths.Modules["Vehicles"] = require(script.Vehicles)
end

-- Logic
Paths.Initialized = true

return Paths
