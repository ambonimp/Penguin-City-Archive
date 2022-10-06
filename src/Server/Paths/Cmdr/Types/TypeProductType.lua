local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtil = require(ReplicatedStorage.Shared.Cmdr.CmdrUtil)
local Products = require(ReplicatedStorage.Shared.Products.Products)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local function stringsGetter()
    return TableUtil.toArray(Products.ProductType)
end

local function stringToObject(productType: string)
    return productType
end

return function(registry)
    registry:RegisterType("productType", CmdrUtil.createTypeDefinition("productType", stringsGetter, stringToObject))
end
