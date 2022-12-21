local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterItemConstants = require(ReplicatedStorage.Shared.CharacterItems.CharacterItemConstants)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)
local CharacterItemUtil = require(ReplicatedStorage.Shared.CharacterItems.CharacterItemUtil)

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

for categoryName, itemConstants in pairs(CharacterItemConstants) do
    -- Create Products
    for itemKey, item in pairs(itemConstants.Items) do
        local model: Model?
        if categoryName == "Outfit" then
            model = ReplicatedStorage.Assets.Character.StarterCharacter:Clone()
            CharacterItemUtil.manequin(model)
            CharacterItemUtil.applyAppearance(model, item.Items)
        else
            model = itemConstants.AssetsPath and characterAssets[itemConstants.AssetsPath][itemKey]
        end

        local productId = ("%s_%s"):format(StringUtil.toCamelCase(categoryName), StringUtil.toCamelCase(itemKey))
        local product: Product = {
            Id = productId,
            Type = ProductConstants.ProductType.CharacterItem,
            DisplayName = getDisplayName(categoryName, item),
            ImageId = item.Icon,
            ImageColor = getImageColor(categoryName, item),
            CoinData = {
                Cost = item.Price,
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
