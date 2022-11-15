local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Products = require(Paths.Shared.Products.Products)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local PetsService = require(Paths.Server.Pets.PetsService)

local petEggProducts = Products.Products.PetEgg
local consumersById: { [string]: (player: Player) -> nil } = {}

for productId, product in pairs(petEggProducts) do
    local productData = ProductUtil.getPetEggProductData(product)

    -- Give an incubating egg then immediately nuke it
    consumersById[productId] = function(player: Player)
        PetsService.addPetEgg(player, productData.PetEggName)
    end
end

return consumersById
