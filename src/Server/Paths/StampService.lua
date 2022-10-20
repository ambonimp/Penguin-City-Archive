local StampService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local Stamps = require(Paths.Shared.Stamps.Stamps)
local DataService = require(Paths.Server.Data.DataService)

function StampService.hasStamp(player: Player, stampId: string, stampTier: Stamps.StampTier | nil)
    local stamp = StampUtil.getStampFromId(stampId)
    if stamp.IsTiered then
        stampTier = stampTier or "Bronze"
    else
        stampTier = nil
    end

    local data = DataService.get(player, StampUtil.getStampDataAddress(stampId))
    if stamp.IsTiered then
        -- FALSE: Bad data
        local ourTier = data and table.find(Stamps.StampTiers, data) and data :: Stamps.StampTier
        if not ourTier then
            return false
        end

        return StampUtil.isTierCoveredByTier(ourTier, stampTier)
    else
        return data and true or false
    end
end

function StampService.getTier(player: Player, stampId: string)
    -- ERROR: Not tiered
    local stamp = StampUtil.getStampFromId(stampId)
    if not stamp.IsTiered then
        error(("Stamp %q is not tiered"):format(stampId))
    end

    return DataService.get(player, StampUtil.getStampDataAddress(stampId)) :: Stamps.StampTier | nil
end

function StampService.addStamp(player: Player, stampId: string, stampTier: Stamps.StampTier | nil)
    local stamp = StampUtil.getStampFromId(stampId)
    if stamp.IsTiered then
        stampTier = stampTier or "Bronze"
    else
        stampTier = nil
    end

    if stamp and not StampService.hasStamp(player, stampId, stampTier) then
        DataService.set(
            player,
            StampUtil.getStampDataAddress(stampId),
            stampTier or true,
            "StampUpdated",
            { StampId = stampId, StampTier = stampTier }
        )
        return true
    end
    return false
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
