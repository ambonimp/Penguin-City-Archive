local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)
local StampConstants = require(ReplicatedStorage.Shared.Stamps.StampConstants)
local Images = require(ReplicatedStorage.Shared.Images.Images)

type Product = typeof(require(ReplicatedStorage.Shared.Products.Products).Product)

local COLOR_BLACK = Color3.fromRGB(20, 20, 20)

local products: { [string]: Product } = {}

local function getImageId(categoryName: string, property: any): string
    if categoryName == "CoverColor" then
        return Images.Icons.Paint
    end

    if categoryName == "CoverPattern" then
        return property
    end

    if categoryName == "TextColor" then
        return Images.Icons.Text
    end

    if categoryName == "Seal" then
        if property.Icon and property.Icon ~= "" then
            return property.Icon
        else
            return Images.Icons.Seal
        end
    end

    error(("Missing edge case %q"):format(categoryName))
end

local function getImageColor(categoryName: string, property: any): Color3
    if categoryName == "CoverColor" then
        return property.Primary
    end

    if categoryName == "CoverPattern" then
        return COLOR_BLACK
    end

    if categoryName == "TextColor" then
        return property
    end

    if categoryName == "Seal" then
        if property.Icon and property.Icon ~= "" then
            return property.IconColor or property.Color
        else
            return property.Color
        end
    end

    error(("Missing edge case %q"):format(categoryName))
end

for categoryName, propertyConstants in pairs(StampConstants.StampBook) do
    -- Create Products
    for propertyKey, property in pairs(propertyConstants) do
        local productId = ("%s_%s"):format(StringUtil.toCamelCase(categoryName), StringUtil.toCamelCase(propertyKey))
        local product: Product = {
            Id = productId,
            Type = ProductConstants.ProductType.StampBook,
            DisplayName = StringUtil.getFriendlyString(propertyKey),
            ImageId = getImageId(categoryName, property),
            ImageColor = getImageColor(categoryName, property),
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
