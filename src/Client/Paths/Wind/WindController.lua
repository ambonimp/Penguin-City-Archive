local WindController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Wind = require(Paths.Client.Wind.Wind)
local Maid = require(Paths.Packages.maid)

local windMaid = Maid.new()

function WindController.startWind()
    windMaid:Cleanup()

    local wind = Wind.new()
    wind:Start()
    windMaid:GiveTask(wind)
end

function WindController.stopWind()
    windMaid:Cleanup()
end

return WindController
