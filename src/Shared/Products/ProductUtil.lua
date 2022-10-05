local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProductUtil = {}

local Products = require(ReplicatedStorage.Shared.Products.Products)

function ProductUtil.getProduct(productType: string, productId: string): Products.Product | nil
    -- ERROR: Bad product type
    local products = Products.Products[productType]
    if not products then
        warn(("Bad productType %q"):format(productType))
    end

    -- ERROR: Bad productId
    local product = products[productId]
    if not product then
        warn(("No product with id %q under productType %q"):format(productId, productType))
    end

    return product
end

return ProductUtil
