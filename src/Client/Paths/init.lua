local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Paths = {}
Paths.Modules = {}
Paths.UI = game.Players.LocalPlayer.PlayerGui:WaitForChild("Interface")
Paths.Templates = ReplicatedStorage.Templates
Paths.Initialized = false


local shared = ReplicatedStorage.Modules
local enums = shared.Enums
local ui = script.UI


function Paths.initialize()
    local ModuleLoader = require(script.ModuleLoader)

    -- Enums
    ModuleLoader.register("GameEnums", enums.Game)
    ModuleLoader.register("VehicleEnums", enums.Vehicles)

    -- Shared
    ModuleLoader.register("Promise", shared.Promise)
    ModuleLoader.register("Remotes", shared.Remotes)
    ModuleLoader.register("Signal", shared.Signal)
    ModuleLoader.register("Maid", shared.Maid)
    ModuleLoader.register("Spring", shared.Spring)

    -- Utils
    ModuleLoader.register("TableUtil", shared.TableUtil)
    ModuleLoader.register("DataUtil", shared.DataUtil)
    ModuleLoader.register("InteractionUtil", shared.InteractionUtil)
    ModuleLoader.register("VehicleUtil", shared.VehicleUtil)

    -- Interface
    ModuleLoader.register("TransitionFX", ui.SpecialEffects.Transitions)
    ModuleLoader.register("VehicleUI", ui.VehiclesUI)

    --
    ModuleLoader.register("PlayerData", script.PlayerData)
    ModuleLoader.register("Character", script.Character)
    ModuleLoader.register("Vehicles", script.Vehicles)

    ModuleLoader.load()
    Paths.Initialized = true

end

return Paths
