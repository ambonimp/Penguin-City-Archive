local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ProductService = require(Paths.Server.Products.ProductService)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)

return function(_context, players: { Player }, productType: string, productId: string)
    local output = ""
    for _, player in pairs(players) do
        local product = ProductUtil.getProduct(productType, productId)
        local amount = ProductService.getProductCount(player, product)

        output ..= (" > %s has %d %s\n"):format(player.Name, amount, product.DisplayName)
    end

    return output
end
