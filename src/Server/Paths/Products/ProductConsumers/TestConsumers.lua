local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Products = require(Paths.Shared.Products.Products)

local testProducts = Products.Products.Test
local consumersById: { [string]: (player: Player) -> nil } = {}

consumersById[testProducts.print_name.Id] = function(player: Player)
    print(player.Name)
end

return consumersById
