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

local screenGui: ScreenGui = Ui.GiftPopup
local contents: Frame = screenGui.Back.Contents
local claimButton = KeyboardButton.new()
local descriptionLabel: TextLabel = contents.Text.Description
local icon: ImageLabel = contents.Icon

function GiftPopupScreen.Init()
    local function leaveState()
        UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.GiftPopup)
    end

    -- Buttons
    do
        claimButton:Mount(contents.Buttons.Claim, true)
        claimButton:SetText("Claim Gift")
        claimButton:SetColor(UIConstants.Colors.Buttons.AvailableGreen)
        claimButton.Pressed:Connect(leaveState)
    end

    -- Register UIState
    do
        local function enter(data: table)
            GiftPopupScreen.open(data)
        end

        local function exit()
            GiftPopupScreen.close()
        end

        UIController.getStateMachine():RegisterStateCallbacks(UIConstants.States.GiftPopup, enter, exit)
    end
end

function GiftPopupScreen.open(data: table)
    -- RETURN: No product or coins!
    local product: Products.Product = data.Product
    local coins: number = data.Coins
    if not (product or coins) then
        warn("Data missing .Product and/or .Coins")
        UIController.getStateMachine():Pop()
        return
    end

    if product then
        -- Text
        descriptionLabel.Text = product.DisplayName

        -- Icon
        if product.ImageId then
            icon.Image = product.ImageId
            icon.Visible = true
        else
            icon.Visible = false
        end
    else
        -- Text
        descriptionLabel.Text = ("%s Coins"):format(StringUtil.commaValue(coins))

        -- Icon
        icon.Image = Images.Coins.Coin
        icon.Visible = true
    end

    screenGui.Enabled = true
end

function GiftPopupScreen.close()
    screenGui.Enabled = false
end

return GiftPopupScreen
