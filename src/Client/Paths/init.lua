local Paths = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules
local Packages = ReplicatedStorage.Packages
local Constants = Shared.Constants
local Ui = script.UI

Paths.Modules = {}
Paths.UI = game.Players.LocalPlayer.PlayerGui:WaitForChild("Interface")
Paths.Templates = ReplicatedStorage.Templates
Paths.Initialized = false

function Paths.initialize()
    local ModuleLoader = require(script.ModuleLoader)

    -- Constants
    ModuleLoader.register("GameConstants", Constants.GameConstants)
    ModuleLoader.register("VehicleConstants", Constants.VehicleConstants)

    -- Packages
    ModuleLoader.register("Promise", Packages.promise)
    ModuleLoader.register("Maid", Packages.maid)

    -- Shared
    ModuleLoader.register("Remotes", Shared.Remotes)
    ModuleLoader.register("Signal", Shared.Signal)
    ModuleLoader.register("Spring", Shared.Spring)

    -- Utils
    ModuleLoader.register("TableUtil", Shared.Utils.TableUtil)
    ModuleLoader.register("DataUtil", Shared.Utils.DataUtil)
    ModuleLoader.register("InteractionUtil", Shared.Utils.InteractionUtil)
    ModuleLoader.register("VehicleUtil", Shared.Utils.VehicleUtil)

    -- Interface
    ModuleLoader.register("TransitionFX", Ui.SpecialEffects.Transitions)
    ModuleLoader.register("VehicleUI", Ui.VehiclesUI)

    --
    ModuleLoader.register("PlayerData", script.PlayerData)
    ModuleLoader.register("Character", script.Character)
    ModuleLoader.register("Vehicles", script.Vehicles)

    ModuleLoader.load()
    Paths.Initialized = true
end

return Paths
