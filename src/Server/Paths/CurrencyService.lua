local CurrencyService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local DataService = require(Paths.Server.Data.DataService)
local CurrencyConstants = require(Paths.Shared.Currency.CurrencyConstants)
local Signal = require(Paths.Shared.Signal)
local Products = require(Paths.Shared.Products.Products)

export type SunkConfig = {
    IsClientOblivious: boolean?,
    Product: Products.Product,
}

--[[
    IsClientOblivious : Whether or not the client is aware of the injection.
        The client may perform it's own injection in an effort to latency, IsClientObvlious should then be disabled.
        In instances whether IsClientOblivious is false, ideally the client will verify the operation's validity and revert if the server deems it invalid.
]]
export type InjectConfig = {
    IsClientOblivious: boolean?,
    OverideClient: boolean?,
    InjectCategory: string,
    IsFromRobux: boolean?,
}

CurrencyService.CoinsUpdated = Signal.new() -- { player: Player, oldCoins: number, newCoins: number }
CurrencyService.CoinsInjected = Signal.new() -- { player: Player, coinsInjected: number, config: InjectConfig }
CurrencyService.CoinsSunk = Signal.new() -- { player: Player, coinsSunk: number, config: SunkConfig }

function CurrencyService.getCoins(player: Player)
    return DataService.get(player, CurrencyConstants.DataAddress) :: number
end

function CurrencyService.setCoins(player: Player, coins: number)
    DataService.set(player, CurrencyConstants.DataAddress, coins, CurrencyConstants.DataUpdatedEvent, {
        OverideClient = true,
    })
end

function CurrencyService.injectCoins(player: Player, injectCoins: number, config: InjectConfig)
    local oldCoins = CurrencyService.getCoins(player)

    DataService.increment(player, CurrencyConstants.DataAddress, injectCoins, CurrencyConstants.DataUpdatedEvent, {
        IsClientOblivious = config.IsClientOblivious,
        Change = injectCoins,
    })

    CurrencyService.CoinsUpdated:Fire(player, oldCoins, CurrencyService.getCoins(player))
    CurrencyService.CoinsInjected:Fire(player, injectCoins, config)
end

function CurrencyService.sinkCoins(player: Player, sinkCoins: number, config: SunkConfig)
    local oldCoins = CurrencyService.getCoins(player)

    DataService.increment(player, CurrencyConstants.DataAddress, -sinkCoins, CurrencyConstants.DataUpdatedEvent, {
        IsClientOblivious = config.IsClientOblivious,
        Change = -sinkCoins,
    })

    CurrencyService.CoinsUpdated:Fire(player, oldCoins, CurrencyService.getCoins(player))
    CurrencyService.CoinsSunk:Fire(player, sinkCoins, config)
end

return CurrencyService
