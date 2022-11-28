local WaterController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)
local WaterAnimator = require(Paths.Client.Zones.Cosmetics.Water.WaterAnimator)

function WaterController.onZoneUpdate(maid: typeof(Maid.new()), zoneModel: Model)
    local WaterAnimator = WaterAnimator.scanZoneModel(zoneModel)
    if WaterAnimator then
        maid:GiveTask(WaterAnimator)
    end
end

return WaterController
