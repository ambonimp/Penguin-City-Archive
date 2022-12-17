local GiftPopupScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local Products = require(Paths.Shared.Products.Products)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local Images = require(Paths.Shared.Images.Images)
local Sound = require(Paths.Shared.Sound)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local Maid = require(Paths.Shared.Maid)
local Widget = require(Paths.Client.UI.Elements.Widget)

local maid = Maid.new()
local screenGui: ScreenGui = Ui.GiftPopup
local contents: Frame = screenGui.Back.Contents
local claimButton = KeyboardButton.new()
local descriptionLabel: TextLabel = contents.Text.Description
local container: ImageLabel = contents.Middle.Container

function GiftPopupScreen.Init()
    local function close()
        UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.GiftPopup)
    end

    -- Buttons
    do
        claimButton:Mount(contents.Buttons.Claim, true)
        claimButton:SetText("Claim Gift")
        claimButton:SetColor(UIConstants.Colors.Buttons.AvailableGreen)
        claimButton.Pressed:Connect(close)
    end

    -- Close
    UIController.registerStateCloseCallback(UIConstants.States.GiftPopup, close)

    -- Register UIState
    UIController.registerStateScreenCallbacks(UIConstants.States.GiftPopup, {
        Boot = GiftPopupScreen.boot,
        Shutdown = nil,
        Maximize = GiftPopupScreen.maximize,
        Minimize = GiftPopupScreen.minimize,
    })
end

function GiftPopupScreen.boot(data: table)
    -- RETURN: No product or coins!
    local product: Products.Product = data.Product
    local coins: number = data.Coins
    if not (product or coins) then
        warn("Data missing .Product and/or .Coins")
        UIController.getStateMachine():Pop()
        return
    end

    maid:Cleanup()
    Sound.play("OpenGift")

    if product then
        descriptionLabel.Text = product.DisplayName
        container.Image = ""

        local widget = Widget.diverseWidgetFromProduct(product)
        widget:Mount(container)
        maid:GiveTask(widget)
    elseif coins then
        descriptionLabel.Text = ("%s Coins"):format(StringUtil.commaValue(coins))
        container.Image = Images.Coins.Coin
    else
        warn("Bad data", data)
        UIController.getStateMachine():Remove(UIConstants.States.GiftPopup)
    end
end

function GiftPopupScreen.maximize()
    ScreenUtil.inDown(screenGui.Back)
    screenGui.Enabled = true
end

function GiftPopupScreen.minimize()
    ScreenUtil.outUp(screenGui.Back)
end

return GiftPopupScreen
