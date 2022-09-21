local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Paths = {}
Paths.Modules = {}
Paths.Initialized = false

local shared = ReplicatedStorage.Modules
local enums = shared.Enums

function Paths.initialize()
    -- Enums
    Paths.Modules["GameEnums"] = require(enums.Game)
    Paths.Modules["VehicleEnums"] = require(enums.Vehicles)

    -- Shared
    Paths.Modules["Promise"] = require(shared.Promise)
    Paths.Modules["Remotes"] = require(shared.Remotes)
    Paths.Modules["Signal"] = require(shared.Signal)
    Paths.Modules["Maid"] = require(shared.Maid)

    -- Utils
    Paths.Modules["TableUtil"] = require(shared.TableUtil)
    Paths.Modules["DataUtil"] = require(shared.DataUtil)
    Paths.Modules["InteractionUtil"] = require(shared.InteractionUtil)
    Paths.Modules["VehicleUtil"] = require(shared.VehicleUtil)

    --
    Paths.Modules["PlayerData"] = require(script.PlayerData)
    Paths.Modules["AnalyticsTracking"] = require(script.AnalyticsTracking)
    Paths.Modules["PlayerLoader"] = require(script.PlayerLoader)
    Paths.Modules["Vehicles"] = require(script.Vehicles)

    Paths.Initialized = true
end

return Paths
