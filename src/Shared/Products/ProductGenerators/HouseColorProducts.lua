local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FurnitureConstants = require(ReplicatedStorage.Shared.Constants.HouseObjects.FurnitureConstants)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local Images = require(ReplicatedStorage.Shared.Images.Images)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)

type Product = typeof(require(ReplicatedStorage.Shared.Products.Products).Product)

local products: { [string]: Product } = {}

for colorName, colorData in pairs(FurnitureConstants.Colors) do
    -- Create Products
    local productId = ("%s_%s"):format(StringUtil.toCamelCase(colorName), tostring(colorData.ImageColor))
    local product: Product = {
        Id = productId,
        Type = ProductConstants.ProductType.HouseColor,
        DisplayName = StringUtil.getFriendlyString(colorName),
        ImageId = Images.Icons.Paint,
        ImageColor = colorData.ImageColor,
        CoinData = {
            Cost = colorData.Price, --!! Temp
        },
        Metadata = {
            ColorName = colorName,
            Color = colorData.ImageColor,
        },
    }

    products[productId] = product
end

return products
