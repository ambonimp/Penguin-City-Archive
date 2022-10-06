local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ProductService = require(Paths.Server.Products.ProductService)

return function(_context, players: { Player })
    local output = ""
    for _, player in pairs(players) do
        output ..= (" > %s\n"):format(player.Name)
        local ownedProducts = ProductService.getOwnedProducts(player)
        for product, amount in pairs(ownedProducts) do
            output ..= ("   > %s x%d\n"):format(product.DisplayName, amount)
        end
    end

    return output
end
