local Paths = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules
local Packages = ReplicatedStorage.Packages
local Constants = Shared.Constants

Paths.Modules = {}
Paths.Initialized = false

-- Intellisense
if false then
    -- Constants
    Paths.Modules["GameConstants"] = require(Constants.GameConstants)
    Paths.Modules["VehicleConstants"] = require(Constants.VehicleConstants)
    Paths.Modules["FrameworkConstants"] = require(Constants.FrameworkConstants)

    -- Packages
    Paths.Modules["Promise"] = require(Packages.promise)
    Paths.Modules["Maid"] = require(Packages.maid)
    Paths.Modules["Cmdr"] = require(Packages.cmdr)

    -- Shared
    Paths.Modules["Remotes"] = require(Shared.Remotes)
    Paths.Modules["Signal"] = require(Shared.Signal)
    Paths.Modules["StateMachine"] = require(Shared.StateMachine)
    Paths.Modules["Limiter"] = require(Shared.Limiter)

    -- Utils
    Paths.Modules["TableUtil"] = require(Shared.Utils.TableUtil)
    Paths.Modules["DataUtil"] = require(Shared.Utils.DataUtil)
    Paths.Modules["InteractionUtil"] = require(Shared.Utils.InteractionUtil)
    Paths.Modules["VehicleUtil"] = require(Shared.Utils.VehicleUtil)
    Paths.Modules["CmdrUtil"] = require(Shared.Utils.CmdrUtil)

    --
    Paths.Modules["PlayerData"] = require(script.PlayerData)
    Paths.Modules["AnalyticsTracking"] = require(script.AnalyticsTracking)
    Paths.Modules["PlayerLoader"] = require(script.PlayerLoader)
    Paths.Modules["Vehicles"] = require(script.Vehicles)
end

function Paths.initialize()
    -- Init Modules
    local ping = tick()
    do
        -- Constants
        Paths.Modules["GameConstants"] = require(Constants.GameConstants)
        Paths.Modules["VehicleConstants"] = require(Constants.VehicleConstants)
        Paths.Modules["FrameworkConstants"] = require(Constants.FrameworkConstants)

        -- Packages
        Paths.Modules["Promise"] = require(Packages.promise)
        Paths.Modules["Maid"] = require(Packages.maid)

        -- Shared
        Paths.Modules["Remotes"] = require(Shared.Remotes)
        Paths.Modules["Signal"] = require(Shared.Signal)
        Paths.Modules["StateMachine"] = require(Shared.StateMachine)
        Paths.Modules["Limiter"] = require(Shared.Limiter)

        -- Utils
        Paths.Modules["TableUtil"] = require(Shared.Utils.TableUtil)
        Paths.Modules["DataUtil"] = require(Shared.Utils.DataUtil)
        Paths.Modules["InteractionUtil"] = require(Shared.Utils.InteractionUtil)
        Paths.Modules["VehicleUtil"] = require(Shared.Utils.VehicleUtil)
        Paths.Modules["CmdrUtil"] = require(Shared.Utils.CmdrUtil)

        --
        Paths.Modules["PlayerData"] = require(script.PlayerData)
        Paths.Modules["AnalyticsTracking"] = require(script.AnalyticsTracking)
        Paths.Modules["PlayerLoader"] = require(script.PlayerLoader)
        Paths.Modules["Vehicles"] = require(script.Vehicles)
        Paths.Modules["CmdrService"] = require(script.Cmdr.CmdrService)
    end

    local pong = tick()
    if Paths.Modules.FrameworkConstants.DisplayPingPong then
        print(("Required all Server Modules in %.4fs"):format(pong - ping))
    end

    -- Logic
    Paths.Initialized = true
end

return Paths
