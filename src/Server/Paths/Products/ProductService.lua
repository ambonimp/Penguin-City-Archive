--[[
    Welcome to the world of products! Anything that the user can purchase (robux, coins, etc..) goes through here. 

    When a user purchases a product, this is what happens:
    1) We add this product to their data profile
    2) We call the handler for this product (if it exists)
        - A handler is called once; either when a product is purchased, or when a player joins the game and owns that product
        - This may hold logic like e.g., informing a service that a player has access to a specific feature
    3) We read through all of the players product data
        3i) If we find any owned products that need to be consumed immediately, consume them!
        - A consumer is called once, then subtracts 1 from the total of that product owned.
        - This may hold logic like adding coins to a player
]]
local ProductService = {}

local MarketplaceService = game:GetService("MarketplaceService")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Products = require(Paths.Shared.Products.Products)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local DataService = require(Paths.Server.Data.DataService)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local Output = require(Paths.Shared.Output)
local CurrencyService = require(Paths.Server.CurrencyService)

local HANDLER_MODULE_NAME_SUFFIX = "Handlers"
local CONSUMER_MODULE_NAME_SUFFIX = "Consumers"
local CLEARED_PRODUCT_KICK_MESSAGE = "We just revoked some product(s) from you; please rejoin."

local handlersByTypeAndId: { [string]: { [string]: (player: Player, isJoining: boolean) -> nil } } = {}
local consumersByTypeAndId: { [string]: { [string]: (player: Player) -> nil } } = {}

-------------------------------------------------------------------------------
-- Internal Getters
-------------------------------------------------------------------------------

local function getHandler(productType: string, productId: string): ((player: Player, isJoining: boolean) -> nil) | nil
    return handlersByTypeAndId[productType] and handlersByTypeAndId[productType][productId]
end

local function getConsumer(productType: string, productId: string): ((player: Player) -> nil) | nil
    return consumersByTypeAndId[productType] and consumersByTypeAndId[productType][productId]
end

local function getProductDataAddress(productType: string, productId: string)
    return ("%s.%s.%s"):format(ProductConstants.DataAddress, productType, productId)
end

-------------------------------------------------------------------------------
-- Data Getters/Setters
-------------------------------------------------------------------------------

-- `amount` defaults to 1
function ProductService.addProduct(player: Player, product: Products.Product, amount: number?)
    amount = amount or 1
    Output.doDebug(ProductConstants.DoDebug, "addProduct", player, product.Type, product.Id, ("x%d"):format(amount))

    -- Manage Data
    local address = getProductDataAddress(product.Type, product.Id)
    DataService.increment(player, address, amount)

    -- Run Handler
    local handler = getHandler(product.Type, product.Id)
    if handler then
        handler(player, false)
    end

    -- Read
    ProductService.readProducts(player)
end

function ProductService.getProductCount(player: Player, product: Products.Product)
    local address = getProductDataAddress(product.Type, product.Id)
    return DataService.get(player, address) or 0
end

function ProductService.hasProduct(player: Player, product: Products.Product)
    return ProductService.getProductCount(player, product) > 0
end

-- Returns a dictionary of all products this player currently owns, and how many of each
function ProductService.getOwnedProducts(player: Player)
    local ownedProducts: { [Products.Product]: number } = {}

    local storedProducts = DataService.get(player, ProductConstants.DataAddress)
    for productType, products in pairs(storedProducts) do
        for productId, amount in pairs(products) do
            local product = ProductUtil.getProduct(productType, productId)
            ownedProducts[product] = amount
        end
    end

    return ownedProducts
end

--[[
    Will clear stored product(s).
    Could cause unintended behaviour.
]]
function ProductService.clearProduct(player: Player, product: Products.Product, kickPlayer: boolean?)
    -- Detract
    local address = getProductDataAddress(product.Type, product.Id)
    DataService.set(player, address, 0)

    -- Read
    ProductService.readProducts(player)

    if kickPlayer then
        player:Kick(CLEARED_PRODUCT_KICK_MESSAGE)
    end
end

--[[
    Will clear all stored products.
    Will very likely cause unintended behaviour.
]]
function ProductService.clearProducts(player: Player, kickPlayer: boolean?)
    DataService.set(player, ProductConstants.DataAddress, {})

    if kickPlayer then
        player:Kick(CLEARED_PRODUCT_KICK_MESSAGE)
    end
end

-------------------------------------------------------------------------------
-- Player Stuff
-------------------------------------------------------------------------------

function ProductService.loadPlayer(player: Player)
    -- Read Products
    ProductService.readProducts(player)

    -- Run handlers
    for product, _ in pairs(ProductService.getOwnedProducts(player)) do
        local handler = getHandler(product.Type, product.Id)
        if handler then
            handler(player, true)
        end
    end
end

function ProductService.promptProductPurchase(player: Player, product: Products.Product, currency: ("Robux" | "Coins")?)
    -- First pick a currency
    if product.CoinData and product.RobuxData then
        if currency == nil then
            local playerCanAffordCoins = product.CoinData.Cost <= CurrencyService.getCoins(player)
            currency = playerCanAffordCoins and "Coins" or "Robux"
        end
    elseif product.CoinData then
        currency = "Coins"
    elseif product.RobuxData then
        currency = "Robux"
    else
        error(("Product %s.%S has neither CoinData or RobuxData. WAT?"):format(product.Type, product.Id))
    end

    -- Prompt Coins
    if currency == "Coins" then
        warn("todo")
        return
    end

    --!! Assume currency == "Robux" from here

    -- Prompt Gamepass
    if product.RobuxData.GamepassId then
        MarketplaceService:PromptGamePassPurchase(player, product.RobuxData.GamepassId)
        return
    end

    -- Prompt Generic Developer Product
    if product.RobuxData.Cost then
        warn("todo")
        return
    end

    -- Prompt Developer Product
    if product.RobuxData.DeveloperProductId then
        MarketplaceService:PromptProductPurchase(player, product.RobuxData.DeveloperProductId)
        return
    end
end

-------------------------------------------------------------------------------
-- Product Logic
-------------------------------------------------------------------------------

-- Goes through the products this player currently owns, and checks if we need to do anything (e.g., immediately consume)
function ProductService.readProducts(player: Player)
    local storedProducts = DataService.get(player, ProductConstants.DataAddress)
    Output.doDebug(ProductConstants.DoDebug, "readProducts", "Stored Products:", storedProducts)

    for productType, products in pairs(storedProducts) do
        for productId, amount in pairs(products) do
            -- Get State
            local address = getProductDataAddress(productType, productId)
            local product = ProductUtil.getProduct(productType, productId)

            -- Run logic off of product
            -- *If* we run any logic, this will exit readProducts + and start from the beginning (may have changed our data). Performatic recursion :D
            if product then
                -- Should we consume?
                if product.IsConsumable and product.ConsumeImmediately and amount > 0 then
                    Output.doDebug(
                        ProductConstants.DoDebug,
                        "readProducts",
                        "Immediately Consume",
                        productType,
                        productId,
                        ("x%d"):format(amount)
                    )
                    -- If amount > 1, recursion will ensure we consume `amount` of this product!
                    ProductService.consumeProduct(player, product)

                    --!! Recurse
                    -- consumeProduct calls readProducts (if it was successful)
                    return
                end

                -- Manage data (e.g., remove if product is totally consumed)
                -- Should not be less than 0, but cover that edge case just in case
                if amount <= 0 then
                    Output.doDebug(
                        ProductConstants.DoDebug,
                        "readProducts",
                        "Clear product",
                        productType,
                        productId,
                        ("x%d"):format(amount)
                    )
                    DataService.set(player, address, nil)

                    --!! Recurse
                    ProductService.readProducts(player)
                    return
                end
            else
                -- WARN: Deprecated product
                warn(("Found deprecated product '%s.%s' under %s; removing"):format(productType, productId, player.Name))
                DataService.set(player, address, nil)

                --!! Recurse
                ProductService.readProducts(player)
                return
            end
        end
    end
end

-- Returns true if success
function ProductService.consumeProduct(player: Player, product: Products.Product)
    Output.doDebug(ProductConstants.DoDebug, "consumeProduct", player, product.Type, product.Id)

    -- FALSE: Does not have!
    local hasProduct = ProductService.hasProduct(player, product)
    if not hasProduct then
        warn(("Cannot consume product '%s.%s'; %s does not have any!"):format(product.Type, product.Id, player.Name))
        return false
    end

    -- FALSE: Not consumable!
    if not product.IsConsumable then
        warn(("Cannot consume product `%s.%s`; not declared as consumable!"):format(product.Type, product.Id))
        return false
    end

    -- Consume
    local consumer = getConsumer(product.Type, product.Id)
    consumer(player)

    -- Detract
    local address = getProductDataAddress(product.Type, product.Id)
    DataService.increment(player, address, -1)

    -- Read + update data
    ProductService.readProducts(player)
    return true
end

-- Write to handlersByTypeAndId and consumersByTypeAndId
do
    -- Handlers
    do
        for _, handlerModule in pairs(Paths.Server.Products.ProductHandlers:GetChildren()) do
            -- ERROR: Could not match productType
            local productType = StringUtil.chopEnd(handlerModule.Name, HANDLER_MODULE_NAME_SUFFIX)
            if not Products.ProductType[productType] then
                error(("Could not process productType %q from handlerModule %s"):format(productType, handlerModule:GetFullName()))
            end

            handlersByTypeAndId[productType] = {}
            local handlersById = require(handlerModule)
            for productId, handler in pairs(handlersById) do
                -- ERROR: Could not match productId
                if not Products.Products[productType][productId] then
                    error(("Could not process productId %q from handlerModule %s"):format(productId, handlerModule:GetFullName()))
                end

                handlersByTypeAndId[productType][productId] = handler
            end
        end
    end

    -- Consumers
    do
        for _, consumerModule in pairs(Paths.Server.Products.ProductConsumers:GetChildren()) do
            -- ERROR: Could not match productType
            local productType = StringUtil.chopEnd(consumerModule.Name, CONSUMER_MODULE_NAME_SUFFIX)
            if not Products.ProductType[productType] then
                error(("Could not process productType %q from consumerModule %s"):format(productType, consumerModule:GetFullName()))
            end

            consumersByTypeAndId[productType] = {}
            local consumersById = require(consumerModule)
            for productId, consumer in pairs(consumersById) do
                -- ERROR: Could not match productId
                if not Products.Products[productType][productId] then
                    error(("Could not process productId %q from consumerModule %s"):format(productId, consumerModule:GetFullName()))
                end

                consumersByTypeAndId[productType][productId] = consumer
            end
        end
    end
end

return ProductService
