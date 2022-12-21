local TelemetryHouseEdited = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local TelemetryService = require(Paths.Server.Telemetry.TelemetryService)
local PlotService = require(Paths.Server.Housing.PlotService)
local Products = require(Paths.Shared.Products.Products)

local function houseEdited(player: Player, product: Products.Product)
    TelemetryService.postPlayerEvent(player, "houseEdited", {
        itemIdAdjusted = product.Id,
    })
end

PlotService.BlueprintChanged:Connect(function(player: Player, product: Products.Product)
    houseEdited(player, product)
end)
PlotService.ObjectPlaced:Connect(function(player: Player, product: Products.Product, _metadata: PlotService.Metadata)
    houseEdited(player, product)
end)
PlotService.ObjectRemoved:Connect(function(player: Player, product: Products.Product, _metadata: PlotService.Metadata)
    houseEdited(player, product)
end)
PlotService.ObjectUpdated:Connect(
    function(player: Player, product: Products.Product, _oldMetadata: PlotService.Metadata, _newMetadata: PlotService.Metadata)
        houseEdited(player, product)
    end
)

return TelemetryHouseEdited
