local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProductUtil = require(ReplicatedStorage.Shared.Products.ProductUtil)

return {
    Name = "clearProduct",
    Aliases = {},
    Description = "Clears a product from players",
    Group = "|productsAdmin",
    Args = {
        {
            Type = "players",
            Name = "players",
            Description = "The players to clear products from",
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
            Type = "boolean",
            Name = "kickPlayer",
            Description = "Whether to kick the player as part of this operation",
            Default = false,
        },
    },
}
