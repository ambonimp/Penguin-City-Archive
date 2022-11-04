local StampService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local Stamps = require(Paths.Shared.Stamps.Stamps)
local DataService = require(Paths.Server.Data.DataService)

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

return StampService
