local GiftPopupScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local Products = require(Paths.Shared.Products.Products)

local screenGui: ScreenGui = Ui.GiftPopup
local contents: Frame = screenGui.Back.Contents
local claimButton = KeyboardButton.new()
local descriptionLabel: TextLabel = contents.Text.Description
local icon: ImageLabel = contents.Icon
local currentProduct: Products.Product

function GiftPopupScreen.Init()
    local function leaveState()
        UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.PromptProduct)
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
    -- RETURN: No product!
    local product: Products.Product = data.Product
    if not product then
        warn("Data missing .Product")
        UIController.getStateMachine():Pop()
        return
    end
    currentProduct = product

    -- Text
    descriptionLabel.Text = currentProduct.DisplayName

    -- Icon
    if currentProduct.ImageId then
        icon.Image = currentProduct.ImageId
        icon.Visible = true
    else
        icon.Visible = false
    end

    screenGui.Enabled = true
end

function GiftPopupScreen.close()
    screenGui.Enabled = false
end

return GiftPopupScreen
