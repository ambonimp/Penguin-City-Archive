--[[
    Represents a player's play session
]]
local Session = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local ZoneUtil = require(ReplicatedStorage.Shared.Zones.ZoneUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local Products = require(ReplicatedStorage.Shared.Products.Products)

type ZoneData = {
    VisitCount: number,
    TimeSpentSeconds: number,
}
type ProductData = {
    WasPurchased: boolean?,
    TimeEquipped: number?,
    EquippedAtTick: number?,
}

export type Session = typeof(Session.new())

function Session.new(player: Player)
    local session = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local startTick = tick()
    local minigameTimeSeconds = 0

    local zoneDataByZoneString: { [string]: ZoneData } = {}
    local currentZone: ZoneConstants.Zone | nil
    local lastZoneReportAtTick = 0
    local productsDataByProductTypeAndProductId: { [string]: { [string]: ProductData } } = {}

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function updateCurrentZone(zone: ZoneConstants.Zone)
        currentZone = zone
        lastZoneReportAtTick = tick()
    end

    -- Gets ProductData + writes to cache if missing
    local function getProductData(product: Products.Product)
        local productData = productsDataByProductTypeAndProductId[product.Type]
            and productsDataByProductTypeAndProductId[product.Type][product.Id]
        if productData then
            return productData
        end

        productData = {}
        productsDataByProductTypeAndProductId[product.Type] = productsDataByProductTypeAndProductId[product.Type] or {}
        productsDataByProductTypeAndProductId[product.Type][product.Id] = productData
        return productData
    end

    -------------------------------------------------------------------------------
    -- Setters
    -------------------------------------------------------------------------------

    function session:AddMinigameTimeSeconds(addSeconds: number)
        minigameTimeSeconds += addSeconds
    end

    function session:ReportZoneTeleport(fromZone: ZoneConstants.Zone, toZone: ZoneConstants.Zone, teleportData: ZoneConstants.TeleportData)
        -- EDGE CASE: Initial teleport, begin population
        if teleportData.IsInitialTeleport then
            warn("initial teleport", toZone)
            updateCurrentZone(toZone)
            return
        end

        -- WARN: No current zone?
        if not currentZone then
            warn("No internal current zone.. initialising cache")
            updateCurrentZone(toZone)
            return
        end

        -- WARN: `fromZone` does not match current zone
        if not ZoneUtil.zonesMatch(fromZone, currentZone) then
            warn(
                ("Internal currentZone %q does not match fromZone %q"):format(
                    ZoneUtil.toString(player, currentZone),
                    ZoneUtil.toString(player, fromZone)
                )
            )
            updateCurrentZone(toZone)
        end

        -- Update current (aka now old) zone
        local zoneString = ZoneUtil.toString(player, currentZone)
        local zoneData: ZoneData = zoneDataByZoneString[zoneString]
            or {
                TimeSpentSeconds = 0,
                VisitCount = 0,
            }
        zoneDataByZoneString[zoneString] = zoneData

        zoneData.TimeSpentSeconds += (tick() - lastZoneReportAtTick)
        zoneData.VisitCount += 1

        updateCurrentZone(toZone)
    end

    function session:ProductEquipped(product: Products.Product)
        local productData = getProductData(product)
        if productData.EquippedAtTick then
            warn(
                ("Inform product %q %q was equipped, but it was already equipped! Internall unequipping then will reequip."):format(
                    product.Type,
                    product.Id
                )
            )
            session:ProductUnequipped(product)
        end

        productData.EquippedAtTick = tick()
    end

    function session:ProductUnequipped(product: Products.Product)
        local productData = getProductData(product)
        if not productData.EquippedAtTick then
            warn(("Inform product %q %q was unequipped, but was never equipped! Aborting."):format(product.Type, product.Id))
            return
        end

        productData.TimeEquipped = (productData.TimeEquipped or 0) + (tick() - productData.EquippedAtTick)
        productData.EquippedAtTick = nil
    end

    function session:ProductPurchased(product: Products.Product)
        local productData = getProductData(product)
        productData.WasPurchased = true
    end

    -------------------------------------------------------------------------------
    -- Getters
    -------------------------------------------------------------------------------

    -- Returns in seconds how long this player has been playing
    function session:GetPlayTime()
        return tick() - startTick
    end

    function session:GetMinigameTimeSeconds()
        return minigameTimeSeconds
    end

    -- Keys are generated by `ZoneUtil.toString(player, zone)`
    function session:GetZoneData()
        local currentZoneDataByZoneString = TableUtil.deepClone(zoneDataByZoneString) :: typeof(zoneDataByZoneString)

        -- We need to add the current playtime for the current zone..
        local currentZoneString = ZoneUtil.toString(player, currentZone)
        local zoneData: ZoneData = currentZoneDataByZoneString[currentZoneString]
            or {
                TimeSpentSeconds = 0,
                VisitCount = 0,
            }
        currentZoneDataByZoneString[currentZoneString] = zoneData

        zoneData.TimeSpentSeconds += (tick() - lastZoneReportAtTick)
        zoneData.VisitCount += 1

        return currentZoneDataByZoneString
    end

    -- Returns { [productType]: { [productId]: ProductData } }
    function session:GetProductData()
        local currentProductDatas =
            TableUtil.deepClone(productsDataByProductTypeAndProductId) :: typeof(productsDataByProductTypeAndProductId)

        -- We need to add the current playtime for equipped products
        for _productType, productDatas in pairs(currentProductDatas) do
            for _productId, productData in pairs(productDatas) do
                if productData.EquippedAtTick then
                    productData.TimeEquipped = (productData.TimeEquipped or 0) + (tick() - productData.EquippedAtTick)
                    productData.EquippedAtTick = nil
                end
            end
        end

        return currentProductDatas
    end

    return session
end

return Session
