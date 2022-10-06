local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ProductService = require(Paths.Server.Products.ProductService)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)

return function(_context, players: { Player }, productType: string, productId: string, amount: number)
    local output = ""
    for _, player in pairs(players) do
        local product = ProductUtil.getProduct(productType, productId)
        local totalOwned = ProductService.getProductCount(player, product)

        if totalOwned == 0 then
            output ..= (" > %s owns no %s - cannot consume!\n"):format(player.Name, product.DisplayName)
        else
            local total = math.min(totalOwned, amount)
            for _ = 1, total do
                ProductService.consumeProduct(player, product)
            end
            output ..= (" > %s Consumed x%d %s\n"):format(player.Name, total, product.DisplayName)
        end
    end

    return output
end
