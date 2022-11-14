local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)
local PetConstants = require(ReplicatedStorage.Shared.Pets.PetConstants)

type Product = typeof(require(ReplicatedStorage.Shared.Products.Products).Product)

local products: { [string]: Product } = {}

for petEggName, _petEgg in pairs(PetConstants.PetEggs) do
    -- Ready
    local readyProductId = ("pet_egg_%s_ready"):format(StringUtil.toCamelCase(petEggName))
    local readyProduct: Product = {
        Id = readyProductId,
        Type = ProductConstants.ProductType.PetEgg,
        DisplayName = ("%s Egg (Ready)"):format(StringUtil.getFriendlyString(petEggName)),
        IsConsumable = true,
        ConsumeImmediately = true,
        Metadata = {
            PetEggName = petEggName,
            IsReady = true,
        },
    }
    products[readyProductId] = readyProduct
end

return products
