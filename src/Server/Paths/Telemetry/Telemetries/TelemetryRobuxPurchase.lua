local TelemetryMinigames = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local TelemetryService = require(Paths.Server.Telemetry.TelemetryService)
local ProductService = require(Paths.Server.Products.ProductService)
local Products = require(Paths.Shared.Products.Products)

ProductService.RobuxPurchase:Connect(
    function(player: Player, amount: number, productId: number, purchaseId: string, product: Products.Product)
        TelemetryService.postPlayerEvent(player, "transactionCompleted", {
            amount = amount,
            productId = productId,
            purchaseId = purchaseId,
            currency = "Robux",
            productName = product.Id,
            productType = product.Type or "unknown",
        })
    end
)

return TelemetryMinigames
