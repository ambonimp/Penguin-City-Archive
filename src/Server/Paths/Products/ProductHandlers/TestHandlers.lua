local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Products = require(Paths.Shared.Products.Products)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local CurrencyService = require(Paths.Server.CurrencyService)
local Output = require(Paths.Shared.Output)

local testProducts = Products.Products.Test
local handlersById: { [string]: (player: Player, isJoining: boolean) -> nil } = {}

local coinLoginRewardProduct = Products.Products.Test.coin_login_reward
local coinLoginRewardAddCoins = coinLoginRewardProduct.Metadata.AddCoins
handlersById[testProducts.coin_login_reward.Id] = function(player: Player, isJoining: boolean)
    -- RETURN: Only run logic on join
    if not isJoining then
        return
    end

    CurrencyService.addCoins(player, coinLoginRewardAddCoins, true)
    Output.doDebug(
        ProductConstants.DoDebug,
        ("%s joined! +%d coins for owning %s"):format(player.Name, coinLoginRewardAddCoins, coinLoginRewardProduct.DisplayName)
    )
end

return handlersById
