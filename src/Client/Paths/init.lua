local Paths = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules
local Packages = ReplicatedStorage.Packages
local Constants = Shared.Constants
local Ui = script.UI

Paths.UI = game.Players.LocalPlayer.PlayerGui:WaitForChild("Interface")
Paths.Templates = ReplicatedStorage.Templates
Paths.Initialized = false
Paths.Modules = {}

-- Intellisense
if false then
    -- Loader
    Paths.Modules["Loader"] = require(script.Loader)

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
    Paths.Modules["Spring"] = require(Shared.Spring)

    -- Utils
    Paths.Modules["TableUtil"] = require(Shared.Utils.TableUtil)
    Paths.Modules["DataUtil"] = require(Shared.Utils.DataUtil)
    Paths.Modules["InteractionUtil"] = require(Shared.Utils.InteractionUtil)
    Paths.Modules["VehicleUtil"] = require(Shared.Utils.VehicleUtil)
    Paths.Modules["CmdrUtil"] = require(Shared.Utils.CmdrUtil)

    -- Interface
    Paths.Modules["TransitionFX"] = require(Ui.SpecialEffects.Transitions)
    Paths.Modules["VehicleUI"] = require(Ui.VehiclesUI)

    --
    Paths.Modules["PlayerData"] = require(script.PlayerData)
    Paths.Modules["Vehicles"] = require(script.Vehicles)
    Paths.Modules["Character"] = require(script.Character)
end

function Paths.initialize()
    -- Init Modules
    local ping = tick()
    do
        -- Loader
        Paths.Modules["Loader"] = require(script.Loader)

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
        Paths.Modules["Spring"] = require(Shared.Spring)

        -- Utils
        Paths.Modules["TableUtil"] = require(Shared.Utils.TableUtil)
        Paths.Modules["DataUtil"] = require(Shared.Utils.DataUtil)
        Paths.Modules["InteractionUtil"] = require(Shared.Utils.InteractionUtil)
        Paths.Modules["VehicleUtil"] = require(Shared.Utils.VehicleUtil)
        Paths.Modules["CmdrUtil"] = require(Shared.Utils.CmdrUtil)

        -- Interface
        Paths.Modules["TransitionFX"] = require(Ui.SpecialEffects.Transitions)
        Paths.Modules["VehicleUI"] = require(Ui.VehiclesUI)

        --
        Paths.Modules["PlayerData"] = require(script.PlayerData)
        Paths.Modules["Vehicles"] = require(script.Vehicles)
        Paths.Modules["Character"] = require(script.Character)
        Paths.Modules["CmdrController"] = require(script.Cmdr.CmdrController)
    end

    local pong = tick()
    if Paths.Modules.FrameworkConstants.DisplayPingPong then
        print(("Required all Client Modules in %.4fs"):format(pong - ping))
    end

    -- Logic
    Paths.Modules.Loader.load()
    Paths.Initialized = true
end

return Paths
