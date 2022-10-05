local Products = {}

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
    IsConsumable: boolean,
    ConsumeImmediately: boolean?,
    Metadata: table?,
    CoinData: ProductCoinData?,
    RobuxData: ProductRobuxData?,
}

local productType: { [string]: string } = {
    Coin = "Coin",
}

local products: { [string]: { [string]: Product } } = {
    --#region Coin
    Coin = {
        coin_bundle_1 = {
            Id = "coin_bundle_1",
            DisplayName = "Coin Bundle 1",
            IsConsumable = true,
            ConsumeImmediately = true,
            RobuxData = {
                DeveloperProductId = 1322070855,
            },
            Metadata = {
                AddCoins = 20,
            },
        },
    },
    --#endregion
}

-- Append `Type` to each product
for someProductType, someProducts in pairs(products) do
    for _, product in pairs(someProducts) do
        product.Type = someProductType
    end
end

Products.ProductType = productType
Products.Products = products

--[[ EXAMPLES 


    GoodExamples = {
        -- Purchasable/promptable only once - and when owned, will print `JoinMessage` when a player who owns this Product joins the game
        OneTimeDevProduct = {
            Id = "one_time_dev_product",
            DisplayName = "One Time Dev Product",
            IsConsumable = false,
            RobuxData = {
                DeveloperProductId = 1337,
            },
            Metadata = {
                JoinMessage = "%s is Azor Ahai",
            },
        },
        -- A one-time bundle that will unlock X items for a player. We can pass a `Robux` cost, and it will use a generic DeveloperProduct to process the purchase
        SomeBundle = {
            Id = "some_bundle",
            DisplayName = "Some Bundle",
            IsConsumable = false,
            RobuxData = {
                Cost = 50,
            },
            Metadata = {
                BundleId = 1,
            },
        },
    } :: { Product },
    BadExamples = {
        -- BAD! Ownership of a gamepass is immutable, we should not have a representative Product like this
        ConsumableGamepass = {
            Id = "consumable_gamepass",
            DisplayName = "Consumable Gamepass",
            IsConsumable = true,
            RobuxData = {
                GamepassId = 1337 + 10,
            },
        },
    },


]]

return Products
