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

function ProductUtil.getGenericProduct(robux: number): Products.GenericProduct | nil
    for _, genericProduct in pairs(Products.GenericProducts) do
        if genericProduct.Robux == robux then
            return genericProduct
        end
    end
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
