local TopBarScreen = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local AnimatedButton = require(Paths.Client.UI.Elements.AnimatedButton)
local CurrencyController = require(Paths.Client.CurrencyController)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)

local COINS_DIFF_SCREEN_PERCENTAGE = 1 / 4
local COINS_DIFF_TWEEN_INFO_POSITION = TweenInfo.new(3.5)
local COINS_DIFF_TWEEN_INFO_TRANSPARENCY = TweenInfo.new(0.6)
local CONTAINER_WIDTH_TEXT_BOUNDS_OFFSET = 48

local container: Frame = Paths.UI.TopBar.Container
local coinImageButton: ImageButton = container.Coin
local coinTextLabel: TextLabel = coinImageButton.Container.Coins

function TopBarScreen.displayCoinsDiff(addCoins: number)
    -- Get UI Elements + setup initial state
    local coinsLabel: TextLabel = coinTextLabel:Clone()
    coinsLabel.Size = UDim2.new(0, 1000, coinsLabel.Size.Y.Scale, coinsLabel.Size.Y.Offset)
    coinsLabel.ZIndex = coinsLabel.ZIndex - 1
    coinsLabel.Text = ("%s%s"):format(addCoins > 0 and "+" or "", StringUtil.commaValue(addCoins))
    coinsLabel.Name = "CoinsDiff"
    coinsLabel.Parent = coinImageButton

    local fadeInstances: { Instance } = { coinsLabel, coinsLabel.UIStroke }

    -- Position
    local yPixels = Workspace.CurrentCamera.ViewportSize.Y * COINS_DIFF_SCREEN_PERCENTAGE
    local startPosition = coinsLabel.Position
        + UDim2.fromOffset(0, container.Size.Y.Offset / 2)
        + UDim2.fromOffset(-coinsLabel.TextBounds.X / 2, 0)
    local goalPosition = startPosition + UDim2.fromOffset(0, yPixels)

    coinsLabel.Position = startPosition

    TweenUtil.tween(coinsLabel, COINS_DIFF_TWEEN_INFO_POSITION, { Position = goalPosition })

    -- Transparency
    InstanceUtil.fadeIn(fadeInstances, COINS_DIFF_TWEEN_INFO_TRANSPARENCY)

    task.delay(COINS_DIFF_TWEEN_INFO_POSITION.Time - COINS_DIFF_TWEEN_INFO_TRANSPARENCY.Time * 2, function()
        InstanceUtil.fadeOut(fadeInstances, COINS_DIFF_TWEEN_INFO_TRANSPARENCY)
    end)

    -- Cleanup
    task.delay(COINS_DIFF_TWEEN_INFO_POSITION.Time, function()
        coinsLabel:Destroy()
    end)
end

-- Coin
do
    local function updateCoins()
        local cachedSize = coinTextLabel.Size
        coinTextLabel.Size = UDim2.new(0, 1234, 1, 0) -- Make it big for TextBounds to be properly calculated
        coinTextLabel.Text = StringUtil.commaValue(CurrencyController.getCoins())

        local widthOffset = coinTextLabel.TextBounds.X + CONTAINER_WIDTH_TEXT_BOUNDS_OFFSET

        coinImageButton.Size = UDim2.new(0, widthOffset, 1, 0)
        coinTextLabel.Size = cachedSize
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
        UIController.getStateMachine():Push(UIConstants.States.Shop, { StartTabName = "Coins" })
    end)
end

return TopBarScreen
