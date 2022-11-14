local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Products = require(Paths.Shared.Products.Products)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local PetService = require(Paths.Server.Pets.PetService)

local petEggProducts = Products.Products.PetEgg
local consumersById: { [string]: (player: Player) -> nil } = {}

for productId, product in pairs(petEggProducts) do
    local eggType = ProductUtil.getPetEggType(product)
    if eggType == "Ready" then
        local productData = ProductUtil.getPetEggProductData(product)
        local readyProduct = ProductUtil.getPetEggProduct(productData.PetEggName, "Incubating")

        -- Give an incubating egg then immediately nuke it
        consumersById[productId] = function(player: Player)
            -- Circular Dependency
            local ProductService = require(Paths.Server.Products.ProductService)

            ProductService.addProduct(player, readyProduct)
            PetService.nukeEgg(player, productData.PetEggName, math.huge)
        end
    end
end

return consumersById
