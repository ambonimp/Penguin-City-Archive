local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Products = require(Paths.Shared.Products.Products)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local PetsService = require(Paths.Server.Pets.PetsService)

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
            local DataService = require(Paths.Server.Data.DataService)

            -- Listen to PetEgg being added to data (to get its index), then nuke it
            local connection: typeof(DataService.Updated:Connect(function() end))
            connection = DataService.Updated:Connect(function(
                event: string,
                somePlayer: Player,
                _newValue: any,
                eventMeta: {
                    IsNewEgg: boolean?,
                    PetEggIndex: string,
                }?
            )
                if event == "PetEggUpdated" and somePlayer == player and eventMeta and eventMeta.IsNewEgg then
                    connection:Disconnect()
                    PetsService.nukeEgg(player, productData.PetEggName, eventMeta.PetEggIndex)
                end
            end)

            -- Add
            ProductService.addProduct(player, readyProduct)
        end
    end
end

return consumersById
