local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ProductService = require(Paths.Server.Products.ProductService)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)

return function(_context, players: { Player }, productType: string, productId: string, forceRobuxPurchase: boolean?)
    local output = ""

    local product = ProductUtil.getProduct(productType, productId)
    if not product then
        return "Bad Product"
    end

    for _, player in pairs(players) do
        ProductService.promptProductPurchase(player, product, forceRobuxPurchase)

        output ..= (" > %s prompted\n"):format(player.Name)
    end

    return output
end
