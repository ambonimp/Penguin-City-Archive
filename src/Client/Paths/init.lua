local Paths = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules
local Packages = ReplicatedStorage.Packages
local Enums = Shared.Enums
local Ui = script.UI

Paths.Modules = {}
Paths.UI = game.Players.LocalPlayer.PlayerGui:WaitForChild("Interface")
Paths.Templates = ReplicatedStorage.Templates
Paths.Initialized = false

function Paths.initialize()
    local ModuleLoader = require(script.ModuleLoader)

    -- Enums
    ModuleLoader.register("GameEnums", Enums.Game)
    ModuleLoader.register("VehicleEnums", Enums.Vehicles)

    -- Packages
    ModuleLoader.register("Promise", Packages.promise)
    ModuleLoader.register("Maid", Packages.maid)

    -- Shared
    ModuleLoader.register("Remotes", Shared.Remotes)
    ModuleLoader.register("Signal", Shared.Signal)
    ModuleLoader.register("Spring", Shared.Spring)

    -- Utils
    ModuleLoader.register("TableUtil", Shared.TableUtil)
    ModuleLoader.register("DataUtil", Shared.DataUtil)
    ModuleLoader.register("InteractionUtil", Shared.InteractionUtil)
    ModuleLoader.register("VehicleUtil", Shared.VehicleUtil)

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
