local ProductProcessReceipt = {}

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ProductService = require(Paths.Server.Products.ProductService)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local DataService = require(Paths.Server.Data.DataService)
local TableUtil = require(Paths.Shared.Utils.TableUtil)

export type ReceiptInfo = {
    PurchaseId: string,
    PlayerId: number,
    ProductId: number,
    CurrencySpent: Enum.CurrencyType,
    PlaceIdWherePurchased: number,
}

local MAX_STORED_PURCHASE_KEYS = 100
local DATA_ADDRESS = "ProductPurchaseReceiptKeys"

function ProductProcessReceipt.isPurchaseReceiptKeyStored(player: Player, purchaseReceiptKey: string)
    local purchaseReceiptKeys = DataService.get(player, DATA_ADDRESS)
    return TableUtil.find(purchaseReceiptKeys, purchaseReceiptKey) and true or false
end

function ProductProcessReceipt.storePurchaseReceiptKey(player: Player, purchaseReceiptKey: string)
    -- Store
    local storeKey = DataService.append(player, DATA_ADDRESS, purchaseReceiptKey)

    -- Clamp amount of keys stored
    local purchaseReceiptKeys = DataService.get(player, DATA_ADDRESS)
    local totalKeys = 0
    for i = tonumber(storeKey), 1, -1 do
        if purchaseReceiptKeys[tostring(i)] then
            totalKeys += 1

            if totalKeys > MAX_STORED_PURCHASE_KEYS then
                purchaseReceiptKeys[tostring(i)] = nil
            end
        else
            -- Reached end
            break
        end
    end
end

-- Returns true if successfully handled
local function handlePurchase(player: Player, receiptInfo: ReceiptInfo)
    local product = ProductUtil.getProductFromDeveloperProductId(receiptInfo.ProductId)
    if product then
        ProductService.addProduct(player, product, 1)
        return true
    else
        warn(("No product found with developerProductId %d"):format(receiptInfo.ProductId))
    end

    return false
end

-- Product Purchases
do
    local function processReceipt(receiptInfo)
        receiptInfo = receiptInfo :: ReceiptInfo -- MarketplaceService.ProcessReceipt doesn't like our custom type

        -- FAILURE: Player not online
        local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
        if not player then
            -- The player probably left the game
            -- If they come back, the callback will be called again
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        -- Determine if product was already granted (stored in datastore)
        local purchaseReceiptKey = ("%s_%d"):format(receiptInfo.PurchaseId, receiptInfo.ProductId)
        local isPurchaseReceiptKeyStored = ProductProcessReceipt.isPurchaseReceiptKeyStored(player, purchaseReceiptKey)

        -- SUCCESS: Already in datastore aka granted
        if isPurchaseReceiptKeyStored then
            return Enum.ProductPurchaseDecision.PurchaseGranted
        end

        -- FAILURE: Handler failed
        local handlerSuccess, handlerResponse = pcall(handlePurchase, player, receiptInfo)
        if not (handlerSuccess and handlerResponse) then
            warn("Error occurred while processing a product purchase. ", player, receiptInfo, "| Response:", tostring(handlerResponse))
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        -- Store purchase Key
        ProductProcessReceipt.storePurchaseReceiptKey(player, purchaseReceiptKey)

        -- SUCCESS
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    MarketplaceService.ProcessReceipt = processReceipt
end

-- Gamepass Purchases
do
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
        -- RETURN: Not purchased
        if not wasPurchased then
            return
        end

        local product = ProductUtil.getProductFromGamepassId(gamepassId)
        if product then
            ProductService.addProduct(player, product, 1)
        else
            warn(("No product found with gamepassId %d"):format(gamepassId))
        end
    end)
end

return ProductProcessReceipt
