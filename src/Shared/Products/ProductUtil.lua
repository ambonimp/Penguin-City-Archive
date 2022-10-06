local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProductUtil = {}

local Products = require(ReplicatedStorage.Shared.Products.Products)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)

function ProductUtil.getProduct(productType: string, productId: string): Products.Product | nil
    -- ERROR: Bad product type
    local products = Products.Products[productType]
    if not products then
        warn(("Bad productType %q"):format(productType))
    end

    -- ERROR: Bad productId
    local product = products[productId]
    if not product then
        warn(("No product with id %q under productType %q"):format(productId, productType))
    end

    return product
end

function ProductUtil.getProductFromDeveloperProductId(developerProductId: number): Products.Product | nil
    for _productType, products in pairs(Products.Products) do
        for _productId, product in pairs(products) do
            if product.RobuxData and product.RobuxData.DeveloperProductId == developerProductId then
                return product
            end
        end
    end
end

function ProductUtil.getProductFromGamepassId(gamepassId: number): Products.Product | nil
    for _productType, products in pairs(Products.Products) do
        for _productId, product in pairs(products) do
            if product.RobuxData and product.RobuxData.GamepassId == gamepassId then
                return product
            end
        end
    end
end

function ProductUtil.getGenericProduct(robux: number): Products.GenericProduct | nil
    for _, genericProduct in pairs(Products.GenericProducts) do
        if genericProduct.Robux == robux then
            return genericProduct
        end
    end
end

function ProductUtil.getGenericProductFromDeveloperProductId(developerProductId: number): Products.GenericProduct | nil
    for _, genericProduct in pairs(Products.GenericProducts) do
        if genericProduct.DeveloperProductId == developerProductId then
            return genericProduct
        end
    end
end

function ProductUtil.getAllGamepassProducts()
    local gamepassProducts: { Products.Product } = {}

    for _productType, products in pairs(Products.Products) do
        for _productId, product in pairs(products) do
            if product.RobuxData and product.RobuxData.GamepassId then
                table.insert(gamepassProducts, product)
            end
        end
    end

    return gamepassProducts
end

function ProductUtil.getProductIdCmdrArgument(productTypeArgument)
    local productType = productTypeArgument:GetValue()
    return {
        Type = ProductUtil.getProductIdCmdrTypeName(productType),
        Name = "productId",
        Description = ("productId (%s)"):format(productType),
    }
end

function ProductUtil.getProductIdCmdrTypeName(productType: string)
    return StringUtil.toCamelCase(("%sproductId"):format(productType))
end

return ProductUtil
