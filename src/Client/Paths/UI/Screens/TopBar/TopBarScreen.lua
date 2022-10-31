local TopBarScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local CurrencyController = require(Paths.Client.CurrencyController)
local StringUtil = require(Paths.Shared.Utils.StringUtil)

local container: Frame = Paths.UI.TopBar.Container

-- Coin
do
    local imageButton: ImageButton = container.Coin

    local function updateCoins()
        imageButton.Coins.Text = StringUtil.commaValue(CurrencyController.getCoins())
        imageButton.White.Text = imageButton.Coins.Text
    end

    CurrencyController.CoinsUpdated:Connect(updateCoins)
    updateCoins()

    local coinButton = AnimatedButton.new(imageButton)
    coinButton.Pressed:Connect(function()
        warn("TODO Prompt Coin Purchases")
    end)
end

return TopBarScreen
