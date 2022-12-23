--[[
    Represents a player's play session
]]
local Session = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConstants = require(ReplicatedStorage.Shared.Zones.ZoneConstants)
local ZoneUtil = require(ReplicatedStorage.Shared.Zones.ZoneUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local Products = require(ReplicatedStorage.Shared.Products.Products)
local PetConstants = require(ReplicatedStorage.Shared.Pets.PetConstants)
local Stamps = require(ReplicatedStorage.Shared.Stamps.Stamps)

type ZoneData = {
    VisitCount: number,
    TimeSpentSeconds: number,
}
type ProductData = {
    WasAcquired: boolean?,
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
    local productsDataByProduct: { [Products.Product]: ProductData } = {}
    local acquiredStamps: { [Stamps.Stamp]: true | Stamps.StampTier } = {}

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function updateCurrentZone(zone: ZoneConstants.Zone)
        currentZone = zone
        lastZoneReportAtTick = tick()
    end

    -- Gets ProductData + writes to cache if missing
    local function getProductData(product: Products.Product)
        productsDataByProduct[product] = productsDataByProduct[product] or {}
        return productsDataByProduct[product]
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
            --[[ warn("initial teleport", toZone) *]]
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
            --[[ warn(
                ("Internal currentZone %q does not match fromZone %q"):format(
                    ZoneUtil.toString(player, currentZone),
                    ZoneUtil.toString(player, fromZone)
                )
            ) *]]
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
            --[[ warn(
                ("Inform product %q %q was equipped, but it was already equipped! Internall unequipping then will reequip."):format(
                    product.Type,
                    product.Id
                )
            ) *]]
            session:ProductUnequipped(product)
        end

        productData.EquippedAtTick = tick()
    end

    function session:ProductUnequipped(product: Products.Product)
        local productData = getProductData(product)
        if not productData.EquippedAtTick then
            --[[ warn(("Inform product %q %q was unequipped, but was never equipped! Aborting."):format(product.Type, product.Id)) *]]
            return
        end

        productData.TimeEquipped = (productData.TimeEquipped or 0) + (tick() - productData.EquippedAtTick)
        productData.EquippedAtTick = nil
    end

    function session:ProductAcquired(product: Products.Product)
        local productData = getProductData(product)
        productData.WasAcquired = true
    end

    function session:StampAcquired(stamp: Stamps.Stamp, stampTier: Stamps.StampTier | nil)
        -- ERROR: Mismatch with stamp being tiered or not, and `stampTier`
        stampTier = stamp.IsTiered and stampTier or nil
        if stamp.IsTiered then
            if not table.find(Stamps.StampTiers, stampTier) then
                error(("Bad StampTier %q for stamp %s"):format(tostring(stampTier), stamp.Id))
            end
        end

        acquiredStamps[stamp] = stampTier or true
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

        -- Player left before they could be loaded into a zone
        if not currentZone then
            return
        end

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

    -- Returns { [Products.Product]: ProductData }
    function session:GetProductData()
        local currentProductDatas: { [Products.Product]: ProductData } = {}

        for product, productData in pairs(productsDataByProduct) do
            local currentProductData = TableUtil.deepClone(productData)
            if currentProductData.EquippedAtTick then
                currentProductData.TimeEquipped = (currentProductData.TimeEquipped or 0) + (tick() - currentProductData.EquippedAtTick)
                currentProductData.EquippedAtTick = nil
            end

            currentProductDatas[product] = currentProductData
        end

        return currentProductDatas
    end

    function session:GetAcquiredStamps()
        return TableUtil.deepClone(acquiredStamps) :: typeof(acquiredStamps)
    end

    return session
end

return Session
