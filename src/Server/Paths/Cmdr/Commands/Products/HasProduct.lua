local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProductUtil = require(ReplicatedStorage.Shared.Products.ProductUtil)

return {
    Name = "hasProduct",
    Aliases = {},
    Description = "Does a player own a product?",
    Group = "|productsAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to query",
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
    },
}
