local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)
local ToolConstants = require(ReplicatedStorage.Shared.Tools.ToolConstants)
local ToolUtil = require(ReplicatedStorage.Shared.Tools.ToolUtil)

type Product = typeof(require(ReplicatedStorage.Shared.Products.Products).Product)

local products: { [string]: Product } = {}

for categoryName, tools in pairs(ToolConstants.Tools) do
    for _, tool in pairs(tools) do
        local productId = ("%s_%s"):format(StringUtil.toCamelCase(categoryName), StringUtil.toCamelCase(tool.Name))
        local product: Product = {
            Id = productId,
            Type = ProductConstants.ProductType.Tool,
            DisplayName = StringUtil.getFriendlyString(("%s %s"):format(tool.Name, categoryName)),
            CoinData = {
                Cost = tool.Price, --!! Temp
            },
            Metadata = {
                CategoryName = categoryName,
                ToolName = tool.Name,
                Model = ToolUtil.getModel(ToolUtil.tool(categoryName, tool.Name)),
            },
        }

        products[productId] = product
    end
end

return products
