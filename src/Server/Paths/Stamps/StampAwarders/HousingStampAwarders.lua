local HousingStampAwarders = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local PlotService = require(Paths.Server.Housing.PlotService)
local StampService = require(Paths.Server.Stamps.StampService)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local ZoneService = require(Paths.Server.Zones.ZoneService)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local DataService = require(Paths.Server.Data.DataService)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local Products = require(Paths.Shared.Products.Products)
local ZoneUtil = require(Paths.Shared.Zones.ZoneUtil)

local placedOtemStamp = StampUtil.getStampFromId("igloo_getting_started")
local colorItemStamp = StampUtil.getStampFromId("igloo_thats_better")
local visitIglooStamp = StampUtil.getStampFromId("igloo_sleepover")
local itemsPlacedStamp = StampUtil.getStampFromId("igloo_decorator")

PlotService.ObjectPlaced:Connect(function(player: Player, product: Products.Product, _metadata: PlotService.Metadata)
    local productData = ProductUtil.getHouseObjectProductData(product)
    if productData.CategoryName == "Furniture" then
        StampService.addStamp(player, placedOtemStamp.Id) -- ADD STAMP

        local amount = DataService.get(player, "House.TotalObjectsPlaced") or 0
        amount += 1
        if amount >= 25 then
            StampService.addStamp(player, itemsPlacedStamp.Id) -- ADD STAMP
        end
        DataService.set(player, "House.TotalObjectsPlaced", amount)
    end
end)

PlotService.ObjectUpdated:Connect(
    function(player: Player, _product: Products.Product, oldMetadata: PlotService.Metadata, newMetadata: PlotService.Metadata)
        local hasDiffColor = false

        -- RETURN: No color metadata
        if not (oldMetadata.Color and newMetadata.Color) then
            return
        end

        for id, color in oldMetadata.Color do
            if newMetadata.Color[id] ~= color then
                hasDiffColor = true
                break
            end
        end

        if hasDiffColor then
            StampService.addStamp(player, colorItemStamp.Id) -- ADD STAMP
        end
    end
)

ZoneService.ZoneChanged:Connect(function(player: Player, _fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone)
    local isVisitingAnotherPlayersIgloo = ZoneUtil.isHouseInteriorZone(toZone)
        and not ZoneUtil.zonesMatch(toZone, ZoneUtil.houseInteriorZone(player))
    if isVisitingAnotherPlayersIgloo then
        StampService.addStamp(player, visitIglooStamp.Id) -- ADD STAMP
    end
end)

return HousingStampAwarders
