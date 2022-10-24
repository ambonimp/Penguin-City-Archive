local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Products = {}

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
}

export type GenericProduct = {
    DeveloperProductId: number,
    Robux: number,
}

-------------------------------------------------------------------------------
-- Products
-------------------------------------------------------------------------------

local productType: { [string]: string } = {
    Coin = "Coin",
    Test = "Test",
}

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
}

local genericProducts: { GenericProduct } = {
    { DeveloperProductId = 1322114146, Robux = 99 },
}

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
