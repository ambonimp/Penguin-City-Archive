local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterItems = require(ReplicatedStorage.Shared.Constants.CharacterItems)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)

type Product = typeof(require(ReplicatedStorage.Shared.Products.Products).Product)

local IGNORE_ITEM_TYPE = {
    "BodyType",
}

local products: { [string]: Product } = {}

for categoryName, itemConstants in pairs(CharacterItems) do
    -- IGNORE: Continue
    if table.find(IGNORE_ITEM_TYPE, categoryName) then
        continue
    end

    -- Create Products
    for itemKey, item in pairs(itemConstants.Items) do
        local productId = ("%s_%s"):format(StringUtil.toCamelCase(categoryName), StringUtil.toCamelCase(itemKey))
        local product: Product = {
            Id = productId,
            Type = ProductConstants.ProductType.CharacterItem,
            DisplayName = StringUtil.getFriendlyString(item.Name),
            ImageId = item.Icon,
            CoinData = {
                Cost = item.Price,
            },
            Metadata = {
                CategoryName = categoryName,
                ItemKey = itemKey,
            },
        }

        products[productId] = product
    end
end

return products
