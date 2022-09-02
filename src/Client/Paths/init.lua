local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Paths = {}
Paths.Modules = {}
Paths.UI = game.Players.LocalPlayer.PlayerGui
Paths.Initialized = false


local shared = ReplicatedStorage.Modules
local enums = shared.Enums


function Paths.initialize()
    local ModuleLoader = require(script.ModuleLoader)

    -- Enums
    ModuleLoader.register("GameEnums", enums.Game)

    -- Shared
    ModuleLoader.register("Promise", shared.Promise)
    ModuleLoader.register("Remotes", shared.Remotes)
    ModuleLoader.register("Signal", shared.Signal)
    -- Utils
    ModuleLoader.register("TableUtil", shared.TableUtil)
    ModuleLoader.register("DataUtil", shared.DataUtil)

    --
    ModuleLoader.register("PlayerData", script.PlayerData)

    ModuleLoader.load()
    Paths.Initialized = true

end

return Paths
