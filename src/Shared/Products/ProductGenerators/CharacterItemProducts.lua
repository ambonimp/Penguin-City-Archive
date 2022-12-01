local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterItems = require(ReplicatedStorage.Shared.Constants.CharacterItems)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)

type Product = typeof(require(ReplicatedStorage.Shared.Products.Products).Product)

local products: { [string]: Product } = {}
local characterAssets: Folder = ReplicatedStorage.Assets.Character

local function getImageColor(categoryName: string, item: any): Color3 | nil
    if categoryName == "FurColor" then
        return item.Color
    end
end

local function getDisplayName(categoryName: string, item: any): string | nil
    if categoryName == "FurColor" then
        return ("%s Fur"):format(StringUtil.getFriendlyString(item.Name))
    end

    return StringUtil.getFriendlyString(item.Name)
end

for categoryName, itemConstants in pairs(CharacterItems) do
    -- Create Products
    for itemKey, item in pairs(itemConstants.Items) do
        local model: Model? = itemConstants.AssetsPath and characterAssets[itemConstants.AssetsPath][itemKey]

        local productId = ("%s_%s"):format(StringUtil.toCamelCase(categoryName), StringUtil.toCamelCase(itemKey))
        local product: Product = {
            Id = productId,
            Type = ProductConstants.ProductType.CharacterItem,
            DisplayName = getDisplayName(categoryName, item),
            ImageId = item.Icon,
            ImageColor = getImageColor(categoryName, item),
            CoinData = {
                Cost = productId:len() % 2, --!! Temp
            },
            Metadata = {
                CategoryName = categoryName,
                ItemKey = itemKey,
                Model = model,
            },
        }

        products[productId] = product
    end
end

return products
