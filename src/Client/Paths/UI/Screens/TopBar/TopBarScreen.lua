local TopBarScreen = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local CurrencyController = require(Paths.Client.CurrencyController)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)

local COINS_DIFF_SCREEN_PERCENTAGE = 1 / 4
local COINS_DIFF_TWEEN_INFO_POSITION = TweenInfo.new(3.5)
local COINS_DIFF_TWEEN_INFO_TRANSPARENCY = TweenInfo.new(0.6)
local COINS_DIFF_OFFSET_START_POSITION = UDim2.fromOffset(-13, 0) -- Account for the "+" at start of string
local INSTANT_TWEEN_INFO = TweenInfo.new(0)

local container: Frame = Paths.UI.TopBar.Container
local coinImageButton: ImageButton = container.Coin

function TopBarScreen.displayCoinsDiff(addCoins: number)
    -- Get UI Elements + setup initial state
    local coinsLabel: TextLabel = coinImageButton.Coins:Clone()
    coinsLabel.ZIndex = coinsLabel.ZIndex - 1
    coinsLabel.Text = ("%s%s"):format(addCoins > 0 and "+" or "", StringUtil.commaValue(addCoins))
    coinsLabel.Name = "CoinsDiff"
    local whiteLabel: TextLabel = coinImageButton.White:Clone()
    whiteLabel.ZIndex = whiteLabel.ZIndex - 1
    whiteLabel.Text = coinsLabel.Text
    whiteLabel.Name = "CoinsDiff"

    local fadeInstances: { Instance } = { coinsLabel, coinsLabel.UIStroke, whiteLabel, whiteLabel.UIStroke }
    InstanceUtil.fadeOut(fadeInstances, INSTANT_TWEEN_INFO)

    -- Position
    local yPixels = Workspace.CurrentCamera.ViewportSize.Y * COINS_DIFF_SCREEN_PERCENTAGE
    local startPosition = coinsLabel.Position + UDim2.fromOffset(0, container.Size.Y.Offset / 2) + COINS_DIFF_OFFSET_START_POSITION
    local goalPosition = startPosition + UDim2.fromOffset(0, yPixels)

    coinsLabel.Position = startPosition
    whiteLabel.Position = startPosition

    TweenUtil.tween(coinsLabel, COINS_DIFF_TWEEN_INFO_POSITION, { Position = goalPosition })
    TweenUtil.tween(whiteLabel, COINS_DIFF_TWEEN_INFO_POSITION, { Position = goalPosition })

    -- Transparency
    InstanceUtil.fadeIn(fadeInstances, COINS_DIFF_TWEEN_INFO_TRANSPARENCY)

    task.delay(COINS_DIFF_TWEEN_INFO_POSITION.Time - COINS_DIFF_TWEEN_INFO_TRANSPARENCY.Time * 2, function()
        InstanceUtil.fadeOut(fadeInstances, COINS_DIFF_TWEEN_INFO_TRANSPARENCY)
    end)

    -- Creation + Destruction
    coinsLabel.Parent = coinImageButton
    whiteLabel.Parent = coinImageButton

    task.delay(COINS_DIFF_TWEEN_INFO_POSITION.Time, function()
        coinsLabel:Destroy()
        whiteLabel:Destroy()
    end)
end

-- Coin
do
    local function updateCoins()
        coinImageButton.Coins.Text = StringUtil.commaValue(CurrencyController.getCoins())
        coinImageButton.White.Text = coinImageButton.Coins.Text
    end

    CurrencyController.CoinsUpdated:Connect(function(_coins: number, addCoins: number)
        updateCoins()
        if math.abs(addCoins) > 0 then
            TopBarScreen.displayCoinsDiff(addCoins)
        end
    end)
    updateCoins()

    local coinButton = AnimatedButton.new(coinImageButton)
    coinButton.Pressed:Connect(function()
        warn("TODO Prompt Coin Purchases")
    end)
end

return TopBarScreen
