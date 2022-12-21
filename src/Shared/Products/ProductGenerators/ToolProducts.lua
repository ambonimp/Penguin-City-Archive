local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)
local ToolConstants = require(ReplicatedStorage.Shared.Tools.ToolConstants)
local ToolUtil = require(ReplicatedStorage.Shared.Tools.ToolUtil)

type Product = typeof(require(ReplicatedStorage.Shared.Products.Products).Product)

local products: { [string]: Product } = {}

for categoryName, tools in pairs(ToolConstants.Tools) do
    for _, tool in pairs(tools) do
        local productId = ("%s_%s"):format(StringUtil.toCamelCase(categoryName), StringUtil.toCamelCase(tool.Id))
        local product: Product = {
            Id = productId,
            Type = ProductConstants.ProductType.Tool,
            DisplayName = tool.DisplayName,
            CoinData = {
                Cost = tool.Price,
            },
            Metadata = {
                CategoryName = categoryName,
                ToolId = tool.Id,
                Model = ToolUtil.getModel(ToolUtil.tool(categoryName, tool.Id)),
            },
        }

        products[productId] = product
    end
end

return products
