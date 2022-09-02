local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Paths = {}
Paths.Modules = {}
Paths.Initialized = false


local shared = ReplicatedStorage.Modules
local enums = shared.Enums

function Paths.initialize()
    -- Enums
    Paths.Modules["GameEnums"] = require(enums.Game)

    -- Shared
    Paths.Modules["Promise"] = require(shared.Promise)
    Paths.Modules["Remotes"] = require(shared.Remotes)
    Paths.Modules["Signal"] = require(shared.Signal)
    -- Utils
    Paths.Modules["TableUtil"] = require(shared.TableUtil)
    Paths.Modules["DataUtil"] = require(shared.DataUtil)

    --
    Paths.Modules["PlayerData"] = require(script.PlayerData)

    Paths.Initialized = true

end

return Paths
