local ProductService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Products = require(Paths.Shared.Products.Products)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)

function ProductService.addProduct(player: Player, product: Products.Product)
    --todo
end

function ProductService.getProduct(player: Player, product: Products.Product)
    --todo
end

function ProductService.hasProduct(player: Player, product: Products.Product)
    return ProductService.getProduct(player, product) > 0
end

function ProductService.consumeProduct(player: Player, product: Products.Product)
    --todo
end

return ProductService
