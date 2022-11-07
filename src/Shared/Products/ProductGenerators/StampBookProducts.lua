local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)
local StampConstants = require(ReplicatedStorage.Shared.Stamps.StampConstants)

type Product = typeof(require(ReplicatedStorage.Shared.Products.Products).Product)

local products: { [string]: Product } = {}

for categoryName, propertyConstants in pairs(StampConstants.StampBook) do
    -- Create Products
    for propertyKey, _property in pairs(propertyConstants) do
        local productId = ("%s_%s"):format(StringUtil.toCamelCase(categoryName), StringUtil.toCamelCase(propertyKey))
        local product: Product = {
            Id = productId,
            Type = ProductConstants.ProductType.StampBook,
            DisplayName = StringUtil.getFriendlyString(propertyKey),
            CoinData = {
                Cost = 0,
            },
            Metadata = {
                CategoryName = categoryName,
                PropertyKey = propertyKey,
            },
        }

        products[productId] = product
    end
end

return products
