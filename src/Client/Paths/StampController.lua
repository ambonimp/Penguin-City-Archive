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

function StampController.hasStamp(stampId: string, stampTier: Stamps.StampTier | nil)
    local stamp = StampUtil.getStampFromId(stampId)
    if stamp.IsTiered then
        stampTier = stampTier or "Bronze"
    else
        stampTier = nil
    end

    local data = DataController.get(StampUtil.getStampDataAddress(stampId))
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
