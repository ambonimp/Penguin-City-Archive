local Products = {}

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)

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
    --#region Test
    Test = {
        coin_login_reward = {
            Id = "coin_login_reward",
            DisplayName = "+5 Coin Login Reward",
            Description = "Gives you +5 coins each time you log in!",
            RobuxData = {
                Cost = 123456789,
                GamepassId = 91726149,
            },
            Metadata = {
                AddCoins = 5,
            },
        },
        print_name = {
            Id = "print_name",
            DisplayName = "Print Name",
            Description = "Prints your name when consumed",
            IsConsumable = true,
            RobuxData = {
                Cost = 99,
            },
            CoinData = {
                Cost = 5,
            },
        },
    },
    --#endregion
    --#region Pet Eggs
    PetEgg = {
        pet_egg_test = {
            Id = "pet_egg_test",
            DisplayName = "Test Egg",
            Description = "Test Egg",
            RobuxData = {
                Cost = 99,
                DeveloperProductId = 1335900877,
            },
            Metadata = {
                PetEggName = "Test",
                IsIncubating = true,
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
