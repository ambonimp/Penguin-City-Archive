local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Products = require(Paths.Shared.Products.Products)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local CurrencyService = require(Paths.Server.CurrencyService)
local Output = require(Paths.Shared.Output)

local coinProducts = Products.Products.Coin
local consumersById: { [string]: (player: Player) -> nil } = {}

-- Generate consumersById table
for productId, product in pairs(coinProducts) do
    -- ERROR: Missing meta data!
    local addCoins = product.Metadata and product.Metadata.AddCoins
    if not addCoins then
        error(("Product Coins.%s has no Metadata.AddCoins"):format(productId))
    end

    -- Write callback
    consumersById[productId] = function(player: Player)
        CurrencyService.addCoins(player, addCoins, true)
        Output.doDebug(ProductConstants.DoDebug, ("Consumed Coin Product %q (%s +%d Coins)"):format(productId, player.Name, addCoins))
    end
end

return consumersById
