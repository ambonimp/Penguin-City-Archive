local WaterController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Shared.Maid)
local WaterAnimator = require(Paths.Client.Zones.Cosmetics.Water.WaterAnimator)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)

function WaterController.onZoneUpdate(maid: Maid.Maid, _zone: ZoneConstants.Zone, zoneModel: Model)
    local waterAnimator = WaterAnimator.scanZoneModel(zoneModel)
    if waterAnimator then
        maid:GiveTask(waterAnimator)
    end
end

return WaterController
