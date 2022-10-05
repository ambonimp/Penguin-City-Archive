local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Products = require(Paths.Shared.Products.Products)
local CurrencyService = require(Paths.Server.CurrencyService)
local Output = require(Paths.Shared.Output)

local coinProducts = Products.Products.Coin
local consumers: { [string]: (player: Player) -> nil } = {}

-- Generate consumers table
for productId, product in pairs(coinProducts) do
    -- ERROR: Missing meta data!
    local addCoins = product.Metadata and product.Metadata.AddCoins
    if not addCoins then
        error(("Product Coins.%s has no Metadata.AddCoins"):format(productId))
    end

    -- Write callback
    consumers[productId] = function(player: Player)
        CurrencyService.addCoins(player, addCoins, true)
        Output.info(("Consumed Coin Product %q (%s +%d Coins)"):format(productId, player.Name, addCoins))
    end
end

return consumers
