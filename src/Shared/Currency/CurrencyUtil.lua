local CurrencyUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Products = require(ReplicatedStorage.Shared.Products.Products)

-------------------------------------------------------------------------------
-- Inject
-------------------------------------------------------------------------------

function CurrencyUtil.injectCategoryFromMinigame(minigameName: string, isDuringMinigame: boolean)
    return ("Minigame_%s_%s"):format(isDuringMinigame and "During" or "Finish", minigameName)
end

function CurrencyUtil.injectCategoryFromCoinProduct(coinProduct: Products.Product)
    return coinProduct.Id
end
return CurrencyUtil
