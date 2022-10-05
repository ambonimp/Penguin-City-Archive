--[[
    Welcome to the world of products! Anything that the user can purchase (robux, coins, etc..) goes through here. 

    When a user purchases a product, this is what happens:
    1) We add this product to their data profile
    2) We call the handler for this product (if it exists)
        - A handler can be called multiple times; all relevant handlers are called when a player joins the game for example
        - This may hold logic like e.g., informing a service that a player has access to a specific feature
    3) We read through all of the players product data
        3i) If we find any owned products that need to be consumed immediately, consume them!
]]
local ProductService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Products = require(Paths.Shared.Products.Products)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local DataService = require(Paths.Server.Data.DataService)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local Output = require(Paths.Shared.Output)

local HANDLER_MODULE_NAME_SUFFIX = "Handlers"
local CONSUMER_MODULE_NAME_SUFFIX = "Consumers"

local handlersByTypeAndId: { [string]: { [string]: (player: Player) -> nil } }
local consumersByTypeAndId: { [string]: { [string]: (player: Player) -> nil } }

local function getHandler(productType: string, productId: string): ((player: Player) -> nil) | nil
    return handlersByTypeAndId[productType] and handlersByTypeAndId[productType][productId]
end

local function getConsumer(productType: string, productId: string): ((player: Player) -> nil) | nil
    return consumersByTypeAndId[productType] and consumersByTypeAndId[productType][productId]
end

-- `amount` defaults to 1
function ProductService.addProduct(player: Player, product: Products.Product, amount: number?)
    amount = amount or 1
    Output.doDebug(ProductConstants.DoDebug, "addProduct", player, product.Type, product.Id, ("x%d"):format(amount))

    -- Manage Data
    local address = ("%s.%s.%s"):format(ProductConstants.DataAddress, product.Type, product.Id)
    DataService.increment(player, address, amount)

    -- Run Handler
    local handler = getHandler(product.Type, product.Id)
    if handler then
        handler(player)
    end

    -- Read
    ProductService.readProducts(player)
end

function ProductService.getProductCount(player: Player, product: Products.Product)
    local address = ("%s.%s.%s"):format(ProductConstants.DataAddress, product.Type, product.Id)
    return DataService.get(player, address) or 0
end

function ProductService.hasProduct(player: Player, product: Products.Product)
    return ProductService.getProductCount(player, product) > 0
end

-- Goes through the products this player currently owns, and checks if we need to do anything (e.g., immediately consume)
function ProductService.readProducts(player: Player)
    local storedProducts = DataService.get(player, ProductConstants.DataAddress)
    Output.doDebug(ProductConstants.DoDebug, "readProducts", "Stored Products:", storedProducts)

    for productType, products in pairs(storedProducts) do
        for productId, amount in pairs(products) do
            -- Get State
            local address = ("%s.%s.%s"):format(ProductConstants.DataAddress, productType, productId)
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

                -- Manage data (remove if product is totally consumed)
                -- Should not be less than 0, but cover that edge case just in case
                local newestAmount = ProductService.getProductCount(player, product)
                if newestAmount <= 0 then
                    Output.doDebug(
                        ProductConstants.DoDebug,
                        "readProducts",
                        "Clear product",
                        productType,
                        productId,
                        ("x%d"):format(newestAmount)
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
    local address = ("%s.%s.%s"):format(ProductConstants.DataAddress, product.Type, product.Id)
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
