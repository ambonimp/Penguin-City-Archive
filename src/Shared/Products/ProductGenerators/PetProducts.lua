local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)
local PetConstants = require(ReplicatedStorage.Shared.Pets.PetConstants)

type Product = typeof(require(ReplicatedStorage.Shared.Products.Products).Product)

local products: { [string]: Product } = {}

for petType, petVariants in pairs(PetConstants.PetVariants) do
    for _, petVariant in pairs(petVariants) do
        local productId = ("%s_%s"):format(StringUtil.toCamelCase(petType), StringUtil.toCamelCase(petVariant))
        local product: Product = {
            Id = productId,
            Type = ProductConstants.ProductType.Pet,
            DisplayName = productId,
            Metadata = {
                PetType = petType,
                PetVariant = petVariant,
            },
        }

        products[productId] = product
    end
end

return products
