local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ProductService = require(Paths.Server.Products.ProductService)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)

return function(_context, players: { Player }, productType: string, productId: string, kickPlayer: boolean)
    local output = ""
    for _, player in pairs(players) do
        local product = ProductUtil.getProduct(productType, productId)
        ProductService.clearProduct(player, product, kickPlayer)

        output ..= (" > %s had all their %s cleared\n"):format(player.Name, product.DisplayName)
    end

    return output
end
