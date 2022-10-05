local ProductService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Products = require(Paths.Shared.Products.Products)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local StringUtil = require(Paths.Shared.Utils.StringUtil)

local HANDLER_MODULE_NAME_SUFFIX = "Handlers"
local CONSUMER_MODULE_NAME_SUFFIX = "Consumers"

local handlersByTypeAndId: { [string]: { [string]: (player: Player) -> nil } }
local consumersByTypeAndId: { [string]: { [string]: (player: Player) -> nil } }

function ProductService.addProduct(player: Player, product: Products.Product)
    --todo
end

function ProductService.getProduct(player: Player, product: Products.Product)
    --todo
end

function ProductService.hasProduct(player: Player, product: Products.Product)
    return ProductService.getProduct(player, product) > 0
end

function ProductService.consumeProduct(player: Player, product: Products.Product)
    --todo
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
