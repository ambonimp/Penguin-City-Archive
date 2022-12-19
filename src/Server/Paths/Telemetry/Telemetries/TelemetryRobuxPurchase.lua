local TelemetryMinigames = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local TelemetryService = require(Paths.Server.Telemetry.TelemetryService)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local ProductService = require(Paths.Server.Products.ProductService)
local Products = require(Paths.Shared.Products.Products)

ProductService.RobuxPurchase:Connect(
    function(player: Player, amount: number, productId: number, purchaseId: string, product: Products.Product)
        TelemetryService.postPlayerEvent(player, "transactionCompleted", {
            amount = amount,
            product_id = productId,
            purchase_id = purchaseId,
            currency = "Robux",
            product_name = product.DisplayName,
            product_type = product.Type or "unknown",
        })
    end
)

return TelemetryMinigames
