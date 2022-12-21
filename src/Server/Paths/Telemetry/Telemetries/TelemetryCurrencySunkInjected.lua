local TelemetryCurrencySunkInjected = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local TelemetryService = require(Paths.Server.Telemetry.TelemetryService)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local CurrencyService = require(Paths.Server.CurrencyService)

local CURRENCY_COINS = "Coins"

local function currencySunk(player: Player, currency: string, amount: number, sinkType: string, productId: string)
    TelemetryService.postPlayerEvent(player, "currencySunk", {
        amount = amount,
        currency = StringUtil.toCamelCase(currency),
        sinkType = StringUtil.toCamelCase(sinkType),
        productId = StringUtil.toCamelCase(productId),
    })
end

local function currencyInjected(player: Player, currency: string, amount: number, injectType: string)
    TelemetryService.postPlayerEvent(player, "currencyInjected", {
        amount = amount,
        currency = StringUtil.toCamelCase(currency),
        injectType = StringUtil.toCamelCase(injectType),
    })
end

CurrencyService.CoinsInjected:Connect(function(player: Player, coinsInjected: number, config: CurrencyService.InjectConfig)
    -- RETURN: Dont post coins injected from robux
    if config.IsFromRobux then
        return
    end

    currencyInjected(player, CURRENCY_COINS, coinsInjected, config.InjectCategory)
end)

CurrencyService.CoinsSunk:Connect(function(player: Player, coinsSunk: number, config: CurrencyService.SunkConfig)
    currencySunk(player, CURRENCY_COINS, coinsSunk, config.Product.Type or "unknown", config.Product.Id)
end)

return TelemetryCurrencySunkInjected