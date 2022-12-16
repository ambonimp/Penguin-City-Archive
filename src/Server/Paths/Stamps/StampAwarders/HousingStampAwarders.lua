local HousingStampAwarders = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local PlotService = require(Paths.Server.Housing.PlotService)
local StampService = require(Paths.Server.Stamps.StampService)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local DataService = require(Paths.Server.Data.DataService)

-- clothing_equip

type FurnitureMetadata = PlotService.FurnitureMetadata
type WallpaperMetadata = PlotService.WallpaperMetadata
type FloorMetadata = PlotService.FloorMetadata

local placedOtemStamp = StampUtil.getStampFromId("igloo_getting_started")
local colorItemStamp = StampUtil.getStampFromId("igloo_thats_better")
local visitIglooStamp = StampUtil.getStampFromId("igloo_sleepover")
local itemsPlacedStamp = StampUtil.getStampFromId("igloo_decorator")

PlotService.ObjectPlaced:Connect(function(player: Player, type: string, _data: FurnitureMetadata | WallpaperMetadata | FloorMetadata)
    if type == "Furniture" then
        StampService.addStamp(player, placedOtemStamp.Id) -- ADD STAMP

        local amount = DataService.get(player, "House.TotalObjectsPlaced") or 0
        amount += 1
        if amount >= 25 then
            StampService.addStamp(player, itemsPlacedStamp.Id) -- ADD STAMP
        end
        DataService.set(player, "House.TotalObjectsPlaced", amount)
    end
end)

PlotService.ObjectUpdated:Connect(function(player: Player, last: FurnitureMetadata, new: FurnitureMetadata)
    local hasDiffColor = false

    for id, color in last.Color do
        if new.Color[id] ~= color then
            hasDiffColor = true
            break
        end
    end

    if hasDiffColor then
        StampService.addStamp(player, colorItemStamp.Id) -- ADD STAMP
    end
end)

ZoneService.ZoneChanged:Connect(function(player: Player, _fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone)
    if tonumber(toZone.ZoneType) and tonumber(toZone.ZoneType) ~= player.UserId then --visintg zone that is a number (assumes it's an id)
        StampService.addStamp(player, visitIglooStamp.Id) -- ADD STAMP
    end
end)

return HousingStampAwarders
