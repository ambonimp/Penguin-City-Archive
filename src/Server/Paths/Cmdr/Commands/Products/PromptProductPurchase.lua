local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProductUtil = require(ReplicatedStorage.Shared.Products.ProductUtil)

return {
    Name = "promptProductPurchase",
    Aliases = {},
    Description = "Prompts the players to purchase a product",
    Group = "|productsAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to add products to",
        },
        {
            Type = "productType",
            Name = "productType",
            Description = "productType",
        },
        function(context)
            local productTypeArgument = context:GetArgument(2)
            return ProductUtil.getProductIdCmdrArgument(productTypeArgument)
        end,
        {
            Type = "number",
            Name = "forceRobuxPurchase",
            Description = "forceRobuxPurchase",
            Optional = true,
        },
    },
}
