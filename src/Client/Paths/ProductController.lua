local ProductController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Products = require(Paths.Shared.Products.Products)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local Remotes = require(Paths.Shared.Remotes)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)

function ProductController.prompt(product: Products.Product, forceRobuxPurchase: boolean?)
    -- Handle on client if coins are allowed
    if product.CoinData and not (forceRobuxPurchase and product.RobuxData) then
        UIController.getStateMachine():Push(UIConstants.States.PromptProduct, {
            Product = product,
        })
        return
    end

    -- Send over to server to handle
    Remotes.fireServer("PromptProductPurchaseOnServer", product.Type, product.Id)
end

function ProductController.purchase(product: Products.Product, currency: "Robux" | "Coins")
    if currency == "Robux" then
        ProductController.prompt(product, true)
        return
    end

    Remotes.fireServer("PurchaseProductInCoins", product.Type, product.Id)
end

-- Communication
Remotes.bindEvents({
    PromptProductPurchaseOnClient = function(productType: string, productId: string)
        local product = ProductUtil.getProduct(productType, productId)
        ProductController.prompt(product)
    end,
})

return ProductController
