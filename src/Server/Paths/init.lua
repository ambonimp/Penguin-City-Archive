local Paths = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules
local Packages = ReplicatedStorage.Packages
local Enums = Shared.Enums

Paths.Modules = {}
Paths.Initialized = false

function Paths.initialize()
	-- Enums
	Paths.Modules["GameEnums"] = require(Enums.Game)
	Paths.Modules["VehicleEnums"] = require(Enums.Vehicles)

	-- Packages
	Paths.Modules["Promise"] = require(Packages.promise)
	Paths.Modules["Maid"] = require(Packages.maid)

	-- Shared
	Paths.Modules["Remotes"] = require(Shared.Remotes)
	Paths.Modules["Signal"] = require(Shared.Signal)

	-- Utils
	Paths.Modules["TableUtil"] = require(Shared.TableUtil)
	Paths.Modules["DataUtil"] = require(Shared.DataUtil)
	Paths.Modules["InteractionUtil"] = require(Shared.InteractionUtil)
	Paths.Modules["VehicleUtil"] = require(Shared.VehicleUtil)

	--
	Paths.Modules["PlayerData"] = require(script.PlayerData)
	Paths.Modules["AnalyticsTracking"] = require(script.AnalyticsTracking)
	Paths.Modules["PlayerLoader"] = require(script.PlayerLoader)
	Paths.Modules["Vehicles"] = require(script.Vehicles)

	Paths.Initialized = true
end

return Paths
