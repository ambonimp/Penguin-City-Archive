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

--[[
    Some Products have a model linked to them (e.g., House Furniture)
]]
function ProductUtil.getModel(product: Products.Product): Model | nil
    return product.Metadata and product.Metadata.Model
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
    if not ProductUtil.isCharacterItemProduct(product) then
        error("Passed a non-CharacterItem product")
    end

    return {
        CategoryName = product.Metadata.CategoryName :: string,
        ItemKey = product.Metadata.ItemKey :: string,
    }
end

function ProductUtil.isCharacterItemProduct(product: Products.Product)
    return product.Type == ProductConstants.ProductType.CharacterItem
end

-------------------------------------------------------------------------------
-- House Objects
-------------------------------------------------------------------------------

function ProductUtil.getHouseObjectProductId(categoryName: string, objectKey: string)
    return ("%s_%s"):format(StringUtil.toCamelCase(categoryName), StringUtil.toCamelCase(objectKey))
end

function ProductUtil.getHouseObjectProduct(categoryName: string, objectKey: string)
    local product =
        Products.Products[ProductConstants.ProductType.HouseObject][ProductUtil.getHouseObjectProductId(categoryName, objectKey)]
    if not product then
        error(("No House Object Product %s.%s"):format(categoryName, objectKey))
    end

    return product
end

function ProductUtil.getHouseObjectProductData(product: Products.Product)
    -- ERROR: Not a HouseObject product
    if not ProductUtil.isHouseObjectProduct(product) then
        error("Passed a non-HouseObject product")
    end

    return {
        CategoryName = product.Metadata.CategoryName :: string,
        ObjectKey = product.Metadata.ObjectKey :: string,
    }
end

function ProductUtil.isHouseObjectProduct(product: Products.Product)
    return product.Type == ProductConstants.ProductType.HouseObject
end

-------------------------------------------------------------------------------
-- StampBook
-------------------------------------------------------------------------------

-- Example: CoverColor, Red
function ProductUtil.getStampBookProductId(categoryName: string, propertyKey: string)
    return ("%s_%s"):format(StringUtil.toCamelCase(categoryName), StringUtil.toCamelCase(propertyKey))
end

function ProductUtil.getStampBookProduct(categoryName: string, propertyKey: string)
    local product = Products.Products[ProductConstants.ProductType.StampBook][ProductUtil.getStampBookProductId(categoryName, propertyKey)]
    if not product then
        error(("No StampBook Product %s.%s"):format(categoryName, propertyKey))
    end

    return product
end

function ProductUtil.getStampBookProductData(product: Products.Product)
    -- ERROR: Not a StampBook product
    if not ProductUtil.isStampBookProduct(product) then
        error("Passed a non-StampBook product")
    end

    return {
        CategoryName = product.Metadata.CategoryName :: string,
        PropertyKey = product.Metadata.PropertyKey :: string,
    }
end

function ProductUtil.isStampBookProduct(product: Products.Product)
    return product.Type == ProductConstants.ProductType.StampBook
end

-------------------------------------------------------------------------------
-- Vehicles
-------------------------------------------------------------------------------

function ProductUtil.getVehicleProductId(vehicleName: string)
    return ("vehicle_%s"):format(StringUtil.toCamelCase(vehicleName))
end

function ProductUtil.getVehicleProduct(vehicleName: string)
    local product = Products.Products[ProductConstants.ProductType.Vehicle][ProductUtil.getVehicleProductId(vehicleName)]
    if not product then
        error(("No Vehicle Product %s"):format(vehicleName))
    end

    return product
end

function ProductUtil.getVehicleProductData(product: Products.Product)
    -- ERROR: Not a Vehicle product
    if not ProductUtil.isVehicleProduct(product) then
        error("Passed a non-Vehicle product")
    end

    return {
        VehicleName = product.Metadata.VehicleName :: string,
    }
end

function ProductUtil.isVehicleProduct(product: Products.Product)
    return product.Type == ProductConstants.ProductType.Vehicle
end

-------------------------------------------------------------------------------
-- PetEggs
-------------------------------------------------------------------------------

function ProductUtil.getPetEggProductId(petEggName: string)
    return ("pet_egg_%s"):format(StringUtil.toCamelCase(petEggName))
end

function ProductUtil.getPetEggProduct(petEggName: string)
    local product = Products.Products.PetEgg[ProductUtil.getPetEggProductId(petEggName)]
    if not product then
        error(("No PetEgg %s Product"):format(petEggName))
    end

    return product
end

function ProductUtil.getPetEggProductData(product: Products.Product)
    -- ERROR: Not a PetEgg product
    if not ProductUtil.isPetEggProduct(product) then
        error("Passed a non-PetEgg product")
    end

    return {
        PetEggName = product.Metadata.PetEggName :: string,
    }
end

function ProductUtil.isPetEggProduct(product: Products.Product)
    return product.Type == ProductConstants.ProductType.PetEgg
end

-------------------------------------------------------------------------------
-- Coins
-------------------------------------------------------------------------------

function ProductUtil.getCoinProductData(product: Products.Product)
    -- ERROR: Not a Coin product
    if not ProductUtil.isCoinProduct(product) then
        error("Passed a non-Coin product")
    end

    return {
        AddCoins = product.Metadata.AddCoins :: number,
    }
end

function ProductUtil.isCoinProduct(product: Products.Product)
    return product.Type == ProductConstants.ProductType.Coin
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
