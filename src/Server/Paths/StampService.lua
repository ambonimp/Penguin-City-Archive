local StampService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local Stamps = require(Paths.Shared.Stamps.Stamps)
local DataService = require(Paths.Server.Data.DataService)

local function getStamp(stampId: string)
    -- ERROR: Bad StampId
    local stamp = StampUtil.getStampFromId(stampId)
    if not stamp then
        error(("Bad StampId %q"):format(stampId))
    end

    return stamp
end

local function processStampProgress(stamp: Stamps.Stamp, stampTierOrProgress: Stamps.StampTier | number | nil)
    if stamp.IsTiered then
        if typeof(stampTierOrProgress) == "string" then
            return stamp.Tiers[stampTierOrProgress]
        else
            return stampTierOrProgress
        end
    else
        return 1
    end
end

local function getStampProgress(player: Player, stampId: string)
    return DataService.get(player, StampUtil.getStampDataAddress(stampId))
end

function StampService.hasStamp(player: Player, stampId: string, stampTierOrProgress: Stamps.StampTier | number | nil)
    local stamp = getStamp(stampId)
    local stampProgress = processStampProgress(stamp, stampTierOrProgress)
    local ourStampProgress = getStampProgress(player, stampId)

    if stamp.IsTiered then
        return ourStampProgress >= stampProgress
    else
        return ourStampProgress and true or false
    end
end

function StampService.getProgress(player: Player, stampId: string)
    return getStampProgress(player, stampId)
end

function StampService.getTier(player: Player, stampId: string)
    -- ERROR: Not tiered
    local stamp = getStamp(stampId)
    if not stamp.IsTiered then
        error(("Stamp %q is not tiered"):format(stampId))
    end

    -- Calculate tier from progress (if applicable)
    local stampProgress = getStampProgress(player, stampId)
    if stampProgress then
        local bestStampTier: string | nil
        for _, stampTier in pairs(Stamps.StampTiers) do
            local stampValue = stamp.Tiers[stampTier]
            if stampProgress >= stampValue then
                bestStampTier = stampTier
            else
                break
            end
        end
        return bestStampTier
    end

    return nil
end

function StampService.addStamp(player: Player, stampId: string, stampTierOrProgress: Stamps.StampTier | number | nil)
    local stamp = getStamp(stampId)
    local stampProgress = processStampProgress(stamp, stampTierOrProgress)

    DataService.set(
        player,
        StampUtil.getStampDataAddress(stampId),
        stampProgress,
        "StampUpdated",
        { StampId = stampId, StampProgress = stampProgress }
    )
    return true
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
