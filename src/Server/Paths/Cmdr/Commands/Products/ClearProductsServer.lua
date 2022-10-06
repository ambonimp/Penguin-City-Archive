local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ProductService = require(Paths.Server.Products.ProductService)

return function(_context, players: { Player }, kickPlayer: boolean)
    local output = ""
    for _, player in pairs(players) do
        ProductService.clearProducts(player, kickPlayer)

        output ..= (" > %s had all their products cleared\n"):format(player.Name)
    end

    return output
end
