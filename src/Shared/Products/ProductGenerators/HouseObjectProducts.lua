local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HouseObjects = require(ReplicatedStorage.Shared.Constants.HouseObjects)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)

type Product = typeof(require(ReplicatedStorage.Shared.Products.Products).Product)

local products: { [string]: Product } = {}

for categoryName, objectConstants in pairs(HouseObjects) do
    -- Create Products
    for objectKey, object in pairs(objectConstants.Objects) do
        local productId = ("%s_%s"):format(StringUtil.toCamelCase(categoryName), StringUtil.toCamelCase(objectKey))
        local product: Product = {
            Id = productId,
            Type = ProductConstants.ProductType.HouseObject,
            DisplayName = StringUtil.getFriendlyString(object.Name),
            ImageId = object.Icon,
            CoinData = {
                Cost = object.Price,
            },
            Metadata = {
                CategoryName = categoryName,
                ObjectKey = objectKey,
            },
        }

        products[productId] = product
    end
end

return products
