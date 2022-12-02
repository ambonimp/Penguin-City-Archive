local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)
local ToolConstants = require(ReplicatedStorage.Shared.Tools.ToolConstants)
local ToolUtil = require(ReplicatedStorage.Shared.Tools.ToolUtil)

type Product = typeof(require(ReplicatedStorage.Shared.Products.Products).Product)

local products: { [string]: Product } = {}

for categoryName, toolNames in pairs(ToolConstants.ToolNames) do
    for _, toolName in pairs(toolNames) do
        local productId = ("%s_%s"):format(StringUtil.toCamelCase(categoryName), StringUtil.toCamelCase(toolName))
        local product: Product = {
            Id = productId,
            Type = ProductConstants.ProductType.Tool,
            DisplayName = StringUtil.getFriendlyString(("%s %s"):format(toolName, categoryName)),
            CoinData = {
                Cost = productId:len() % 2, --!! Temp
            },
            Metadata = {
                CategoryName = categoryName,
                ToolName = toolName,
                Model = ToolUtil.getModel(ToolUtil.tool(categoryName, toolName)),
            },
        }

        products[productId] = product
    end
end

return products
