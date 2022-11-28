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
        coin_pile = {
            Id = "coin_pile",
            DisplayName = "Coin Pile",
            Description = "+650 Coins",
            IsConsumable = true,
            ConsumeImmediately = true,
            ImageId = "rbxassetid://11152356045",
            RobuxData = {
                Cost = 50,
                DeveloperProductId = 1322070855,
            },
            Metadata = {
                AddCoins = 650,
            },
        },
        coin_bag = {
            Id = "coin_bag",
            DisplayName = "Coin Bag",
            Description = "+2,100 Coins",
            IsConsumable = true,
            ConsumeImmediately = true,
            ImageId = "rbxassetid://11152355987",
            RobuxData = {
                Cost = 125,
                DeveloperProductId = 1341513203,
            },
            Metadata = {
                AddCoins = 2100,
            },
        },
        coin_stack = {
            Id = "coin_stack",
            DisplayName = "Coin Stack",
            Description = "+4,350 Coins",
            IsConsumable = true,
            ConsumeImmediately = true,
            ImageId = "rbxassetid://11152355907",
            RobuxData = {
                Cost = 240,
                DeveloperProductId = 1341513286,
            },
            Metadata = {
                AddCoins = 4350,
            },
        },
        coin_chest = {
            Id = "coin_chest",
            DisplayName = "Coin Chest",
            Description = "+7,500 Coins",
            IsConsumable = true,
            ConsumeImmediately = true,
            ImageId = "rbxassetid://11152355811",
            RobuxData = {
                Cost = 330,
                DeveloperProductId = 1341513286,
            },
            Metadata = {
                AddCoins = 7500,
            },
        },
        coin_vault = {
            Id = "coin_vault",
            DisplayName = "Coin Vault",
            Description = "+15,000 Coins",
            IsConsumable = true,
            ConsumeImmediately = true,
            ImageId = "rbxassetid://11152355721",
            RobuxData = {
                Cost = 500,
                DeveloperProductId = 1341513438,
            },
            Metadata = {
                AddCoins = 15000,
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
