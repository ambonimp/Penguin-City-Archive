local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Products = require(ReplicatedStorage.Shared.Products.Products)
local ProductUtil = require(ReplicatedStorage.Shared.Products.ProductUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)

return function()
    local issues: { string } = {}

    local function testProduct(productType: string, product: Products.Product)
        local productName = ("%s.%s"):format(productType, product.Id)
        local function addIssue(issue: string)
            table.insert(issues, ("[%s] %s"):format(productName, issue))
        end

        -- RobuxData
        if product.RobuxData then
            if product.RobuxData.Cost then
                -- DeveloperProductId/GamepassId
                if product.RobuxData.DeveloperProductId and product.RobuxData.GamepassId then
                    addIssue("Only define one DeveloperProductId or GamepassId")
                end

                -- If neither, do we have a matching generic product?
                if not (product.RobuxData.DeveloperProductId or product.RobuxData.GamepassId) then
                    local robux = product.RobuxData.Cost
                    local genericProduct = ProductUtil.getGenericProduct(robux)
                    if not genericProduct then
                        addIssue(("No matching genericProduct found for a RobuxData.Cost of %d"):format(robux))
                    end
                end
            else
                addIssue("Needs a Cost!")
            end

            -- Gamepass products cannot be consumable!
            if product.RobuxData.GamepassId and product.IsConsumable then
                addIssue("Gamepass products cannot be consumable!")
            end
        end

        -- CoinData
        if product.CoinData and not product.CoinData.Cost then
            addIssue("CoinData has no .Cost")
        end

        -- Needs a type
        if product.Type == nil then
            addIssue("Needs a .Type (should be automatically populated though)")
        end
    end

    local function testCharacterItemProduct(product: Products.Product)
        local productName = ("%s.%s"):format("CharacterItem", product.Id)
        local function addIssue(issue: string)
            table.insert(issues, ("[%s] %s"):format(productName, issue))
        end

        -- Product Id must match ProductUtil getter
        local characterItemData = ProductUtil.getCharacterItemProductData(product)
        if product.Id ~= ProductUtil.getCharacterItemProductId(characterItemData.CategoryName, characterItemData.ItemKey) then
            addIssue("ProductId does not match return value for ProductUtil.getCharacterItemProductId")
        end
    end

    local function testHouseObjectProduct(product: Products.Product)
        local productName = ("%s.%s"):format("HouseObject", product.Id)
        local function addIssue(issue: string)
            table.insert(issues, ("[%s] %s"):format(productName, issue))
        end

        -- Product Id must match ProductUtil getter
        local houseObjectData = ProductUtil.getHouseObjectProductData(product)
        if product.Id ~= ProductUtil.getCharacterItemProductId(houseObjectData.CategoryName, houseObjectData.ObjectKey) then
            addIssue("ProductId does not match return value for ProductUtil.getHouseObjectProductData")
        end
    end

    local function testVehicleProduct(product: Products.Product)
        local productName = ("%s.%s"):format("Vehicle", product.Id)
        local function addIssue(issue: string)
            table.insert(issues, ("[%s] %s"):format(productName, issue))
        end

        -- Product Id must match ProductUtil getter
        local vehicleData = ProductUtil.getVehicleProductData(product)
        if product.Id ~= ProductUtil.getVehicleProductId(vehicleData.VehicleName) then
            addIssue("ProductId does not match return value for ProductUtil.getVehicleProductData")
        end
    end

    local function testPetEggProduct(product: Products.Product)
        local productName = ("%s.%s"):format("PetEgg", product.Id)
        local function addIssue(issue: string)
            table.insert(issues, ("[%s] %s"):format(productName, issue))
        end

        -- Product Id must match ProductUtil getter
        local petEggData = ProductUtil.getPetEggProductData(product)
        if product.Id ~= ProductUtil.getPetEggProductId(petEggData.PetEggName) then
            addIssue("ProductId does not match return value for ProductUtil.getPetEggProductData")
        end

        -- Must consume immediately!
        if not (product.IsConsumable and product.ConsumeImmediately) then
            addIssue("Must consume immediately!")
        end
    end

    local function testCoinProduct(product: Products.Product)
        local productName = ("%s.%s"):format("Coin", product.Id)
        local function addIssue(issue: string)
            table.insert(issues, ("[%s] %s"):format(productName, issue))
        end

        -- Needs AddCoins defined
        local coinData = ProductUtil.getCoinProductData(product)
        if not coinData.AddCoins then
            addIssue("No Metadata.AddCoins defined!")
        end

        -- Must consume immediately!
        if not (product.IsConsumable and product.ConsumeImmediately) then
            addIssue("Must consume immediately!")
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

            if productTypeKey == ProductConstants.ProductType.CharacterItem then
                testCharacterItemProduct(product)
            end

            if productTypeKey == ProductConstants.ProductType.HouseObject then
                testHouseObjectProduct(product)
            end

            if productTypeKey == ProductConstants.ProductType.Vehicle then
                testVehicleProduct(product)
            end

            if productTypeKey == ProductConstants.ProductType.PetEgg then
                testPetEggProduct(product)
            end

            if productTypeKey == ProductConstants.ProductType.Coin then
                testCoinProduct(product)
            end
        end
    end

    return issues
end
