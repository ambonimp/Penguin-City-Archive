local ProductController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Products = require(Paths.Shared.Products.Products)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local Remotes = require(Paths.Shared.Remotes)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local CurrencyController = require(Paths.Client.CurrencyController)
local Promise = require(Paths.Packages.promise)

-- Returns a boolean whether we can afford it or not. Returns nil if product cannot be purchased with coins
function ProductController.canAffordInCoins(product: Products.Product)
    if product.CoinData then
        return product.CoinData.Cost <= CurrencyController.getCoins()
    end

    return nil
end

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

--[[
    Returns a Promise that resolves with a boolean value indicating if it was a successful purchase or not.
]]
function ProductController.purchase(product: Products.Product, currency: "Robux" | "Coins")
    if currency == "Robux" then
        ProductController.prompt(product, true)
        return
    end

    -- Request server + handle clientside coins
    CurrencyController.addCoins(-product.CoinData.Cost)
    local serverResponsePromise = Promise.new(function(resolve, _reject, _onCancel)
        resolve(Remotes.invokeServer("PurchaseProductInCoins", product.Type, product.Id))
    end):andThen(function(wasSuccess: boolean)
        if not wasSuccess then
            CurrencyController.addCoins(product.CoinData.Cost)
        end
    end)

    return serverResponsePromise
end

-- Communication
Remotes.bindEvents({
    PromptProductPurchaseOnClient = function(productType: string, productId: string)
        local product = ProductUtil.getProduct(productType, productId)
        ProductController.prompt(product)
    end,
    AddProduct = function(productType: string, productId: string, amount: number)
        print(("+%d %s %s Product"):format(amount, productType, productId))
    end,
})

return ProductController
