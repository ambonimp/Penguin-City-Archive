local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ProductService = require(Paths.Server.Products.ProductService)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)

return function(_context, players: { Player }, productType: string, productId: string)
    local output = ""
    for _, player in pairs(players) do
        local product = ProductUtil.getProduct(productType, productId)
        ProductService.promptProductPurchase(player, product)

        output ..= (" > %s prompted\n"):format(player.Name)
    end

    return output
end
