local StampService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local Stamps = require(Paths.Shared.Stamps.Stamps)
local DataService = require(Paths.Server.Data.DataService)
local Remotes = require(Paths.Shared.Remotes)
local StampConstants = require(Paths.Shared.Stamps.StampConstants)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local ProductService = require(Paths.Server.Products.ProductService)

local function getStamp(stampId: string): Stamps.Stamp
    -- ERROR: Bad StampId
    local stamp = StampUtil.getStampFromId(stampId)
    if not stamp then
        error(("Bad StampId %q"):format(stampId))
    end

    return stamp
end

function StampService.getProgress(player: Player, stampId: string): number
    return DataService.get(player, StampUtil.getStampDataAddress(stampId)) or 0
end

function StampService.hasStamp(player: Player, stampId: string, stampTierOrProgress: Stamps.StampTier | number | nil)
    local stamp = getStamp(stampId)
    local stampProgress = StampUtil.calculateProgressNumber(stamp, stampTierOrProgress)
    local ourStampProgress = StampService.getProgress(player, stampId)

    if stamp.IsTiered then
        return ourStampProgress >= stampProgress
    else
        return ourStampProgress > 0
    end
end

function StampService.getTier(player: Player, stampId: string): string | nil
    -- ERROR: Not tiered
    local stamp = getStamp(stampId)
    if not stamp.IsTiered then
        error(("Stamp %q is not tiered"):format(stampId))
    end

    -- Calculate tier from progress (if applicable)
    local stampProgress = StampService.getProgress(player, stampId)
    return StampUtil.getTierFromProgress(stamp, stampProgress)
end

function StampService.addStamp(player: Player, stampId: string, stampTierOrProgress: Stamps.StampTier | number | nil)
    local stamp = getStamp(stampId)
    local stampProgress = stamp.IsTiered and StampUtil.calculateProgressNumber(stamp, stampTierOrProgress) or 1

    DataService.set(
        player,
        StampUtil.getStampDataAddress(stampId),
        stampProgress,
        "StampUpdated",
        { StampId = stampId, StampProgress = stampProgress }
    )
end

--[[
    Used for increasing the progress of a tiered stamp
    - `amount` defaults to `1`
]]
function StampService.incrementStamp(player: Player, stampId: string, amount: number?)
    amount = amount or 1

    local stamp = getStamp(stampId)
    local currentStampProgress = StampService.getProgress(player, stamp.Id)
    local newProgress = currentStampProgress + amount

    -- Edge Case for non-tiered stamp
    if not stamp.IsTiered then
        newProgress = 1

        if StampService.getProgress(player, stampId) == newProgress then
            return
        end
    end

    DataService.set(
        player,
        StampUtil.getStampDataAddress(stampId),
        newProgress,
        "StampUpdated",
        { StampId = stampId, StampProgress = newProgress }
    )
end

function StampService.revokeStamp(player: Player, stampId: string)
    local stamp = StampUtil.getStampFromId(stampId)
    if stamp and StampService.hasStamp(player, stampId) then
        DataService.set(player, StampUtil.getStampDataAddress(stampId), nil, "StampUpdated", { StampId = stampId })
        return true
    end
    return false
end

-- Communication
do
    Remotes.bindEvents({
        StampBookData = function(player: Player, dirtyStampBookData: any)
            -- RETURN: Needs a table
            if not typeof(dirtyStampBookData) == "table" then
                return
            end

            -- Apply StampBook changes (CoverColor/CoverPattern/TextColor/Seal)
            for categoryName, properties in pairs(StampConstants.StampBook) do
                local propertyName = dirtyStampBookData[categoryName]
                if propertyName and properties[propertyName] then
                    local product = ProductUtil.getStampBookProduct(categoryName, propertyName)
                    if product and (ProductService.hasProduct(player, product) or ProductUtil.isFree(product)) then
                        local address = ("Stamps.StampBook.%s"):format(categoryName)
                        DataService.set(player, address, propertyName)
                    else
                        warn(("Player %s does not own product %q"):format(player.Name, tostring(product and product.Id)))
                    end
                elseif propertyName then
                    warn(("%s Bad StampBookData %s %s"):format(player.Name, categoryName, propertyName))
                end
            end

            -- StampIds
            local dirtyCoverStampIds = dirtyStampBookData.CoverStampIds
            local coverStampIds: { [string]: string } = {}
            if typeof(dirtyCoverStampIds) == "table" then
                for i, entry in ipairs(dirtyCoverStampIds) do
                    local stampId = tostring(entry)
                    local stamp = StampUtil.getStampFromId(stampId)
                    if stamp and StampService.hasStamp(player, stampId) then
                        coverStampIds[tostring(i)] = stampId
                    end
                end
            end
            DataService.set(player, "Stamps.StampBook.CoverStampIds", coverStampIds)
        end,
    })
end

return StampService
