local StampController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local DataController = require(Paths.Client.DataController)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local Stamps = require(Paths.Shared.Stamps.Stamps)
local Signal = require(Paths.Shared.Signal)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)

StampController.StampUpdated = Signal.new() -- {Stamp: Stamp, isOwned: boolean, stampTier: Stamps.StampTier | nil}

local function getStamp(stampId: string): Stamps.Stamp
    -- ERROR: Bad StampId
    local stamp = StampUtil.getStampFromId(stampId)
    if not stamp then
        error(("Bad StampId %q"):format(stampId))
    end

    return stamp
end

function StampController.getProgress(stampId: string, ownedStamps: { [string]: number } | nil): number
    if ownedStamps then
        return ownedStamps[stampId] or 0
    end

    return DataController.get(StampUtil.getStampDataAddress(stampId)) or 0
end

--[[
    Can pass `ownedStamps` if we're querying another players' stamp data
]]
function StampController.hasStamp(
    stampId: string,
    stampTierOrProgress: Stamps.StampTier | number | nil,
    ownedStamps: { [string]: number } | nil
)
    local stamp = getStamp(stampId)
    local stampProgress = StampUtil.calculateProgressNumber(stamp, stampTierOrProgress)
    local ourStampProgress = StampController.getProgress(stampId, ownedStamps)

    if stamp.IsTiered then
        return ourStampProgress >= stampProgress
    else
        return ourStampProgress > 0
    end
end

function StampController.getTier(stampId: string, ownedStamps: { [string]: number } | nil): string | nil
    -- ERROR: Not tiered
    local stamp = getStamp(stampId)
    if not stamp.IsTiered then
        error(("Stamp %q is not tiered"):format(stampId))
    end

    -- Calculate tier from progress (if applicable)
    local stampProgress = StampController.getProgress(stampId, ownedStamps)
    return StampUtil.getTierFromProgress(stamp, stampProgress)
end

function StampController.openStampBook(player: Player)
    if UIController.getStateMachine():HasState(UIConstants.States.StampBook) then
        warn("StampBook already open")
        return
    end

    UIController.getStateMachine():Push(UIConstants.States.StampBook, {
        Player = player,
    })
end

-- Updated Event
do
    DataController.Updated:Connect(function(event: string, newValue: any, meta: table?)
        -- RETURN: Not StampUpdated
        if event ~= "StampUpdated" then
            return
        end

        -- WARN: No stampId
        local stampId: string = meta and meta.StampId
        if not stampId then
            warn("Got StampUpdated event; no StampId?")
            return
        end

        -- RETURN: No valid stamp
        local stamp = StampUtil.getStampFromId(stampId)
        if not stamp then
            return
        end

        local stampTier: Stamps.StampTier | nil = meta and meta.StampTier

        -- Inform
        local hasStamp = newValue and true or false
        StampController.StampUpdated:Fire(stamp, hasStamp, stampTier)
    end)
end

--!!temp
StampController.StampUpdated:Connect(print)

return StampController
