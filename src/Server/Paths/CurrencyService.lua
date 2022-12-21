local CurrencyService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local DataService = require(Paths.Server.Data.DataService)
local CurrencyConstants = require(Paths.Shared.Currency.CurrencyConstants)
local Signal = require(Paths.Shared.Signal)
local Products = require(Paths.Shared.Products.Products)

export type SunkConfig = {
    OverrideClient: boolean?,
    Product: Products.Product,
}

export type InjectConfig = {
    OverrideClient: boolean?,
    InjectCategory: string,
    IsFromRobux: boolean?,
}

CurrencyService.CoinsUpdated = Signal.new() -- { player: Player, oldCoins: number, newCoins: number }
CurrencyService.CoinsInjected = Signal.new() -- { player: Player, coinsInjected: number, config: InjectConfig }
CurrencyService.CoinsSunk = Signal.new() -- { player: Player, coinsSunk: number, config: SunkConfig }

function CurrencyService.getCoins(player: Player)
    return DataService.get(player, CurrencyConstants.DataAddress) :: number
end

function CurrencyService.setCoins(player: Player, coins: number, overrideClient: boolean?)
    DataService.set(player, CurrencyConstants.DataAddress, coins, CurrencyConstants.DataUpdatedEvent, {
        OverrideClient = overrideClient,
    })
end

function CurrencyService.injectCoins(player: Player, injectCoins: number, config: InjectConfig)
    local oldCoins = CurrencyService.getCoins(player)

    DataService.increment(player, CurrencyConstants.DataAddress, injectCoins, CurrencyConstants.DataUpdatedEvent, {
        OverrideClient = config.OverrideClient,
    })

    CurrencyService.CoinsUpdated:Fire(player, oldCoins, CurrencyService.getCoins(player))
    CurrencyService.CoinsInjected:Fire(player, injectCoins, config)
end

function CurrencyService.sinkCoins(player: Player, sinkCoins: number, config: SunkConfig)
    local oldCoins = CurrencyService.getCoins(player)

    DataService.increment(player, CurrencyConstants.DataAddress, -sinkCoins, CurrencyConstants.DataUpdatedEvent, {
        OverrideClient = config.OverrideClient,
    })

    CurrencyService.CoinsUpdated:Fire(player, oldCoins, CurrencyService.getCoins(player))
    CurrencyService.CoinsSunk:Fire(player, sinkCoins, config)
end

return CurrencyService
