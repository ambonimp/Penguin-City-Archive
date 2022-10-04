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
    DisplayName: string,
    IsConsumable: boolean,
    Metadata: table?,
    CoinData: ProductCoinData?,
    RobuxData: ProductRobuxData?,
}

Products.Products = {
    Coins = {
        {
            Id = "coin_bundle_1",
            DisplayName = "Coin Bundle 1",
            IsConsumable = true,
            CoinData = {
                Cost = 10,
            },
            Metadata = {
                AddCoins = 20,
            },
        },
    } :: { Product },
}

return Products
