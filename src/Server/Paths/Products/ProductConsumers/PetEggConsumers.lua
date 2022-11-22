local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Products = require(Paths.Shared.Products.Products)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local PetService = require(Paths.Server.Pets.PetService)

local petEggProducts = Products.Products.PetEgg
local consumersById: { [string]: (player: Player) -> nil } = {}

for productId, product in pairs(petEggProducts) do
    local productData = ProductUtil.getPetEggProductData(product)

    -- Convert products to a pet egg
    consumersById[productId] = function(player: Player)
        PetService.addPetEgg(player, productData.PetEggName)
    end
end

return consumersById
