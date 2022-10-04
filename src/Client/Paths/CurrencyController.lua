local CurrencyController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local DataController = require(Paths.Client.DataController)
local CurrencyConstants = require(Paths.Shared.Constants.CurrencyConstants)
local Signal = require(Paths.Shared.Signal)

CurrencyController.CoinsUpdated = Signal.new() -- {coins: number, addCoins: number}

local cachedCoins: number = 0

function CurrencyController.Init()
    -- Possible future circular Dependencies
    local UIController = require(Paths.Client.UI.UIController)
    local UIConstants = require(Paths.Client.UI.UIConstants)

    -- Init cache
    CurrencyController.readData()

    -- Ensure correct coins (do this while user is loading, nice and hidden)
    UIController.getStateMachine():RegisterStateCallbacks(UIConstants.States.Loading, CurrencyController.readData)

    -- Listen to server override
    DataController.Updated:Connect(function(event: string, _newValue: any, eventMeta: table?)
        if event == CurrencyConstants.DataUpdatedEvent then
            if eventMeta and eventMeta.OverrideClient then
                CurrencyController.readData()
            end
        end
    end)

    --!! TEMP
    CurrencyController.CoinsUpdated:Connect(print)
end

function CurrencyController.getCoins()
    return cachedCoins
end

function CurrencyController.setCoins(coins: number)
    local addCoins = coins - cachedCoins
    return CurrencyController.addCoins(addCoins)
end

--[[
    Adds coins clientside
    - Returns a function that can be invoked to revert this addition. This is useful if we incorrectly assume a server response.
]]
function CurrencyController.addCoins(addCoins: number)
    cachedCoins += addCoins
    CurrencyController.CoinsUpdated:Fire(cachedCoins, addCoins)

    local didRevert = false
    return function()
        if didRevert then
            return
        end
        didRevert = true

        CurrencyController.addCoins(-addCoins)
    end
end

-- Use this over .addCoins when it is a *reward*. We may want to apply a multiplier here in the future!
function CurrencyController.rewardCoins(addCoins: number)
    local multiplier = 1
    local finalCoins = addCoins * multiplier
    return CurrencyController.addCoins(finalCoins), finalCoins
end

-- Will update our clientside coins to match that of the server
function CurrencyController.readData()
    CurrencyController.setCoins(DataController.get(CurrencyConstants.DataAddress) :: number)
end

return CurrencyController
