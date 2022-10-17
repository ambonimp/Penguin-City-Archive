local StampController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local DataController = require(Paths.Client.DataController)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local Signal = require(Paths.Shared.Signal)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)

StampController.StampUpdated = Signal.new() -- {Stamp: Stamp, isOwned: boolean}

function StampController.hasStamp(stampId: string)
    return DataController.get(StampUtil.getStampDataAddress(stampId)) and true or false
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

        -- Inform
        local hasStamp = newValue and true or false
        StampController.StampUpdated:Fire(stamp, hasStamp)
    end)
end

--!!temp
StampController.StampUpdated:Connect(print)

return StampController
