local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtil = require(ReplicatedStorage.Shared.Cmdr.CmdrUtil)
local Products = require(ReplicatedStorage.Shared.Products.Products)
local ProductUtil = require(ReplicatedStorage.Shared.Products.ProductUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

return function(registry)
    -- We have to create a uniqe productId type for each productType
    for productType, products in pairs(Products.Products) do
        local function stringsGetter()
            return TableUtil.getKeys(products)
        end

        local function stringToObject(productId: string)
            return productId
        end

        local typeName = ProductUtil.getProductIdCmdrTypeName(productType)
        registry:RegisterType(typeName, CmdrUtil.createTypeDefinition(typeName, stringsGetter, stringToObject))
    end
end
