local Products = {}

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)
local Images = require(ReplicatedStorage.Shared.Images.Images)

-------------------------------------------------------------------------------
-- Types
-------------------------------------------------------------------------------

export type ProductCoinData = {
    Cost: number,
}

export type ProductRobuxData = {
    Cost: number?,
    DeveloperProductId: number?,
    GamepassId: number?,
}

export type Product = {
    Id: string,
    Type: string?,
    DisplayName: string,
    IsConsumable: boolean?,
    ConsumeImmediately: boolean?,
    Metadata: table?,
    CoinData: ProductCoinData?,
    RobuxData: ProductRobuxData?,
    Description: string?,
    ImageId: string?,
    ImageColor: Color3?,
}

export type GenericProduct = {
    DeveloperProductId: number,
    Robux: number,
}

-------------------------------------------------------------------------------
-- Products
-------------------------------------------------------------------------------

local assets: Folder = ReplicatedStorage.Assets
local productType: { [string]: string } = ProductConstants.ProductType

local products: { [string]: { [string]: Product } } = {
    --#region Coin
    Coin = {
        coin_bundle_1 = {
            Id = "coin_bundle_1",
            DisplayName = "Coin Bundle 1",
            Description = "+20 Coins",
            IsConsumable = true,
            ConsumeImmediately = true,
            RobuxData = {
                Cost = 49,
                DeveloperProductId = 1322070855,
            },
            Metadata = {
                AddCoins = 20,
            },
        },
    },
    --#endregion
    --#region Pet Eggs
    PetEgg = {
        pet_egg_common = {
            Id = "pet_egg_common",
            DisplayName = "Common Egg",
            Description = "Common Egg",
            ImageId = Images.Pets.Eggs.Blue,
            IsConsumable = true,
            ConsumeImmediately = true,
            RobuxData = {
                Cost = 99,
                DeveloperProductId = 1335900877,
            },
            CoinData = {
                Cost = 5,
            },
            Metadata = {
                PetEggName = "Common",
                Model = assets.Pets.Eggs.Blue,
            },
        },
        pet_egg_rare = {
            Id = "pet_egg_rare",
            DisplayName = "Rare Egg",
            Description = "Rare Egg",
            ImageId = Images.Pets.Eggs.Purple,
            IsConsumable = true,
            ConsumeImmediately = true,
            RobuxData = {
                Cost = 149,
                DeveloperProductId = 1339311091,
            },
            Metadata = {
                PetEggName = "Rare",
                Model = assets.Pets.Eggs.Purple,
            },
        },
        pet_egg_legendary = {
            Id = "pet_egg_legendary",
            DisplayName = "Legendary Egg",
            Description = "Legendary Egg",
            ImageId = Images.Pets.Eggs.Gold,
            IsConsumable = true,
            ConsumeImmediately = true,
            RobuxData = {
                Cost = 299,
                DeveloperProductId = 1339311146,
            },
            Metadata = {
                PetEggName = "Legendary",
                Model = assets.Pets.Eggs.Gold,
            },
        },
    },
    --#endregion
    --#region Misc
    Misc = {
        quick_hatch = {
            Id = "quick_hatch",
            DisplayName = "Quick Hatch",
            Description = "Instantly hatches an egg",
            RobuxData = {
                Cost = 49,
                DeveloperProductId = 1337359490,
            },
        },
    },
    --#endregion
}

local genericProducts: { GenericProduct } = {
    { DeveloperProductId = 1322114146, Robux = 99 },
}

-------------------------------------------------------------------------------
-- Generated Products
-------------------------------------------------------------------------------

local productGenerators = ReplicatedStorage.Shared.Products.ProductGenerators
for _, generatorScript: ModuleScript in pairs(productGenerators:GetChildren()) do
    local generatorProductType = StringUtil.chopEnd(generatorScript.Name, "Products")
    local generatorProducts = require(generatorScript)

    products[generatorProductType] = products[generatorProductType] or {}
    for generatedId, generatedProduct in pairs(generatorProducts) do
        products[generatorProductType][generatedId] = generatedProduct
    end
end

-------------------------------------------------------------------------------
-- Logic / Assign to scope
-------------------------------------------------------------------------------

-- Append `Type` to each product
for someProductType, someProducts in pairs(products) do
    for _, product in pairs(someProducts) do
        product.Type = someProductType
    end
end

-- Write `Robux` value to each genericProduct directly from roblox servers
-- Yields, and is only needed on the server
if RunService:IsServer() then
    for _, genericProduct in pairs(genericProducts) do
        -- WARN: No product info
        local productInfo = MarketplaceService:GetProductInfo(genericProduct.DeveloperProductId, Enum.InfoType.Product)
        if not productInfo then
            warn(
                ("Not able to get ProductInfo for GenericProduct %d. Bad Id or no access to API services."):format(
                    genericProduct.DeveloperProductId
                )
            )
            break
        end

        if productInfo.IsForSale then
            genericProduct.Robux = productInfo.PriceInRobux
        end
    end
end

Products.ProductType = productType
Products.Products = products
Products.GenericProducts = genericProducts

return Products
