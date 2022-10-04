local CurrencyService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local DataService = require(Paths.Server.Data.DataService)
local CurrencyConstants = require(Paths.Shared.Constants.CurrencyConstants)
local Signal = require(Paths.Shared.Signal)

CurrencyService.CoinsUpdated = Signal.new() -- {player: Player, coins: number, eventMeta: {OverrideClient: boolean}?}

function CurrencyService.getCoins(player: Player)
    return DataService.get(player, CurrencyConstants.DataAddress) :: number
end

function CurrencyService.setCoins(player: Player, coins: number, overrideClient: boolean?)
    DataService.set(player, CurrencyConstants.DataAddress, coins, CurrencyConstants.DataUpdatedEvent, {
        OverrideClient = overrideClient,
    })
end

function CurrencyService.addCoins(player: Player, addCoins: number, overrideClient: boolean?)
    DataService.increment(player, CurrencyConstants.DataAddress, addCoins, CurrencyConstants.DataUpdatedEvent, {
        OverrideClient = overrideClient,
    })
end

-- Use this over .addCoins when it is a *reward*. We may want to apply a multiplier here in the future!
function CurrencyService.rewardCoins(player: Player, addCoins: number, overrideClient: boolean?)
    local multiplier = 1
    local finalCoins = addCoins * multiplier
    CurrencyService.addCoins(player, finalCoins, overrideClient)

    return finalCoins
end

-- CurrencyService.CoinsUpdated
DataService.Updated:Connect(function(event: string, player: Player, newValue: any, eventMeta: table?)
    if event == CurrencyConstants.DataUpdatedEvent then
        CurrencyService.CoinsUpdated:Fire(player, newValue, eventMeta)
    end
end)

return CurrencyService
