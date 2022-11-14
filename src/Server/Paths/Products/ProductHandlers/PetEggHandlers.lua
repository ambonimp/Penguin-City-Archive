local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Products = require(Paths.Shared.Products.Products)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local PetService = require(Paths.Server.Pets.PetService)

local petEggProducts = Products.Products.PetEgg
local handlersById: { [string]: (player: Player, isJoining: boolean) -> nil } = {}

for productId, product in pairs(petEggProducts) do
    local eggType = ProductUtil.getPetEggType(product)
    if eggType == "Incubating" then
        -- Instantiate egg hatch timers
        handlersById[productId] = function(player: Player, _isJoining: boolean)
            PetService.updateIncubation(player)
        end
    end
end

return handlersById
