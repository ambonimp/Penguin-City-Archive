local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ProductService = require(Paths.Server.Products.ProductService)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)

return function(_context, players: { Player }, productType: string, productId: string, amount: number)
    local output = ""
    for _, player in pairs(players) do
        local product = ProductUtil.getProduct(productType, productId)
        ProductService.addProduct(player, product, amount)

        output ..= (" > %s +%d %s\n"):format(player.Name, amount, product.DisplayName)
    end

    return output
end
