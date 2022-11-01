local ProductUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Products = require(ReplicatedStorage.Shared.Products.Products)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)

-------------------------------------------------------------------------------
-- Getters
-------------------------------------------------------------------------------

function ProductUtil.getProductDataAddress(productType: string, productId: string)
    return ("%s.%s.%s"):format(ProductConstants.DataAddress, productType, productId)
end

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

-------------------------------------------------------------------------------
-- Logic
-------------------------------------------------------------------------------

function ProductUtil.isFree(product: Products.Product)
    return product.CoinData and product.CoinData.Cost <= 0 and true or false
end

-------------------------------------------------------------------------------
-- Character Items
-------------------------------------------------------------------------------

function ProductUtil.getCharacterItemProductId(categoryName: string, itemKey: string)
    return ("%s_%s"):format(StringUtil.toCamelCase(categoryName), StringUtil.toCamelCase(itemKey))
end

function ProductUtil.getCharacterItemProduct(categoryName: string, itemKey: string)
    local product =
        Products.Products[ProductConstants.ProductType.CharacterItem][ProductUtil.getCharacterItemProductId(categoryName, itemKey)]
    if not product then
        error(("No Character Item Product %s.%s"):format(categoryName, itemKey))
    end

    return product
end

function ProductUtil.getCharacterItemProductData(product: Products.Product)
    -- ERROR: Not a CharacterItem product
    if product.Type ~= ProductConstants.ProductType.CharacterItem then
        error("Passed a non-CharacterItem product")
    end

    return {
        CategoryName = product.Metadata.CategoryName,
        ItemKey = product.Metadata.ItemKey,
    }
end

-------------------------------------------------------------------------------
-- Cmdr
-------------------------------------------------------------------------------

function ProductUtil.getProductIdCmdrArgument(productTypeArgument)
    local productType = productTypeArgument:GetValue()
    return {
        Type = ProductUtil.getProductIdCmdrTypeName(productType),
        Name = "productId",
        Description = ("productId (%s)"):format(productType),
    }
end

function ProductUtil.getProductIdCmdrTypeName(productType: string)
    return StringUtil.toCamelCase(("%sProductId"):format(productType))
end

return ProductUtil
