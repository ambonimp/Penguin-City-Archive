local ProcessReceipt = {}

local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local ProductService = require(Paths.Server.Products.ProductService)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)

export type ReceiptInfo = {
    PurchaseId: string,
    PlayerId: number,
    ProductId: number,
    CurrencySpent: Enum.CurrencyType,
    PlaceIdWherePurchased: number,
}

local PURCHASE_HISTORY_STORE_NAME = "PurchaseHistory"

local purchaseHistoryStore = DataStoreService:GetDataStore(PURCHASE_HISTORY_STORE_NAME)

-- Returns true if successfully handled
local function handlePurchase(player: Player, receiptInfo: ReceiptInfo)
    local product = ProductUtil.getProductFromDeveloperProductId(receiptInfo.ProductId)
    if product then
        ProductService.addProduct(player, product, 1)
        return true
    else
        error(("No product found with developerProductId %d"):format(receiptInfo.ProductId))
    end

    return false
end

local function processReceipt(receiptInfo)
    receiptInfo = receiptInfo :: ReceiptInfo -- MarketplaceService.ProcessReceipt doesn't like our custom type

    -- Determine if product was already granted (stored in datastore)
    local playerPurchaseKey = ("%d_%d_%s"):format(receiptInfo.PlayerId, receiptInfo.ProductId, receiptInfo.PurchaseId)
    local isPurchased = false
    local getDatastoreSuccess, getDatastoreErrorMessage = pcall(function()
        isPurchased = purchaseHistoryStore:GetAsync(playerPurchaseKey)
    end)

    -- SUCCESS: Already in datastore aka granted
    -- FAILURE: Datastore error
    if getDatastoreSuccess and isPurchased then
        return Enum.ProductPurchaseDecision.PurchaseGranted
    elseif getDatastoreErrorMessage then
        warn(("%s DataStore error: \n%s"):format(PURCHASE_HISTORY_STORE_NAME, getDatastoreErrorMessage))
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- FAILURE: Player not online
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        -- The player probably left the game
        -- If they come back, the callback will be called again
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- FAILURE: Handler failed
    local handlerSuccess, handlerErrorMessage = pcall(handlePurchase, player, receiptInfo)
    if not handlerSuccess then
        warn("Error occurred while processing a product purchase. ", player, receiptInfo, tostring(handlerErrorMessage))
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- FALIURE: Datastore error
    local setDatastoreSuccess, setDatastoreErrorMessage = pcall(function()
        purchaseHistoryStore:SetAsync(playerPurchaseKey, true)
    end)
    if not setDatastoreSuccess then
        warn("Error saving purchase to datastore: " .. setDatastoreErrorMessage)
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- SUCCESS
    -- We got our `player` object
    -- Our handler ran without failure
    -- We recorded this purchase without failure

    return Enum.ProductPurchaseDecision.PurchaseGranted
end
MarketplaceService.ProcessReceipt = processReceipt

return ProcessReceipt
