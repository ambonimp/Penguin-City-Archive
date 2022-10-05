local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Products = require(ReplicatedStorage.Shared.Products.Products)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

return function()
    local issues: { string } = {}

    local function testProduct(productType: string, product: Products.Product)
        local productName = ("%s.%s"):format(productType, product.Id)
        local function addIssue(issue: string)
            table.insert(issues, ("[%s] %s"):format(productName, issue))
        end

        -- IsConsumable => ConsumeImmediately ~= nil
        if product.IsConsumable and product.ConsumeImmediately == nil then
            addIssue("IsConsumable == true - please define ConsumeImmediately (currently nil)")
        end

        -- Members of ProductRobuxData cannot mutually coexist
        if product.RobuxData and TableUtil.length(product.RobuxData) ~= 1 then
            addIssue("RobuxData must have exactly 1 entry (Cost/DeveloperProductId/GamepassId)")
        end

        -- Needs a type
        if product.Type == nil then
            addIssue("Needs a .Type (should be automatically populated though)")
        end
    end

    -- ProductType must have key == value
    for key, value in pairs(Products.ProductType) do
        if key ~= value then
            table.insert(issues, ("Products.ProductType mismatch %q:%q - must be equal!"):format(key, value))
        end
    end

    -- Products
    for productTypeKey, products in pairs(Products.Products) do
        -- Key must be a good productType
        if not Products.ProductType[productTypeKey] then
            table.insert(issues, ("Key %q in Products.Products is not a valid ProductType"):format(productTypeKey))
        end

        for productIdKey, product in pairs(products) do
            -- Key must match product.Id
            if productIdKey ~= product.Id then
                table.insert(
                    issues,
                    ("Product '%s.%s' - key must match Id (%q ~= %q)"):format(productTypeKey, productIdKey, productIdKey, product.Id)
                )
            end

            testProduct(productTypeKey, product)
        end
    end

    return issues
end
