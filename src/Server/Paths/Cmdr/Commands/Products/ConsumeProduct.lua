local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProductUtil = require(ReplicatedStorage.Shared.Products.ProductUtil)

return {
    Name = "consumeProduct",
    Aliases = {},
    Description = "Consumes a product for a player",
    Group = "|productsAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to consume products for",
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
            Name = "amount",
            Description = "How many to consume",
            Default = 1,
        },
    },
}
