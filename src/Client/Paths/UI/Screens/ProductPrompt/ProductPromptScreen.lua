local ResultsScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local Products = require(Paths.Shared.Products.Products)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local ProductController = require(Paths.Client.ProductController)
local Images = require(Paths.Shared.Images.Images)
local CurrencyController = require(Paths.Client.CurrencyController)

local screenGui: ScreenGui = Ui.ProductPrompt
local contents: Frame = screenGui.Back.Contents
local robuxButton = KeyboardButton.new()
local cancelButton = KeyboardButton.new()
local coinsButton = KeyboardButton.new()
local closeButton = ExitButton.new()
local titleLabel: TextLabel = contents.Text.Title
local descriptionLabel: TextLabel = contents.Text.Description
local icon: ImageLabel = contents.Icon
local currentProduct: Products.Product

function ResultsScreen.Init()
    local function leaveState()
        UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.PromptProduct)
    end

    -- Buttons
    do
        closeButton:Mount(screenGui.Back.CloseButton, true)
        closeButton.Pressed:Connect(leaveState)

        robuxButton:Mount(contents.Buttons.Robux, true)
        robuxButton:SetIcon(Images.Icons.Robux)
        robuxButton:SetColor(UIConstants.Colors.Buttons.AvailableGreen)
        robuxButton.Pressed:Connect(function()
            leaveState()
            ProductController.purchase(currentProduct, "Robux")
        end)

        cancelButton:Mount(contents.Buttons.Cancel, true)
        cancelButton:SetColor(UIConstants.Colors.Buttons.CloseRed)
        cancelButton:SetText("Cancel")
        cancelButton.Pressed:Connect(leaveState)

        coinsButton:Mount(contents.Buttons.Coins, true)
        coinsButton:SetIcon(Images.Coins.Coin)
        coinsButton.Pressed:Connect(function()
            local canAfford = currentProduct.CoinData.Cost <= CurrencyController.getCoins()

            if canAfford then
                leaveState()
                ProductController.purchase(currentProduct, "Coins")
            else
                warn("todo prompt coin purchase to afford")
            end
        end)
    end

    -- Register UIState
    do
        local function enter(data: table)
            ResultsScreen.open(data)
        end

        local function exit()
            ResultsScreen.close()
        end

        UIController.getStateMachine():RegisterStateCallbacks(UIConstants.States.PromptProduct, enter, exit)
    end
end

function ResultsScreen.open(data: table)
    -- RETURN: No product!
    local product: Products.Product = data.Product
    if not product then
        warn("Data missing .Product")
        UIController.getStateMachine():Pop()
        return
    end
    currentProduct = product

    -- Text
    titleLabel.Text = currentProduct.DisplayName
    descriptionLabel.Text = currentProduct.Description or ""

    -- Icon
    if currentProduct.ImageId then
        icon.Image = currentProduct.ImageId
        icon.Visible = true
    else
        icon.Visible = false
    end

    -- Robux Button
    robuxButton:GetButtonObject().Parent.Visible = currentProduct.RobuxData and true or false
    if currentProduct.RobuxData then
        local robuxText = currentProduct.RobuxData.Cost and StringUtil.commaValue(currentProduct.RobuxData.Cost) or "???"
        robuxButton:SetText(robuxText, true)
    end

    -- Coin Button
    coinsButton:GetButtonObject().Parent.Visible = currentProduct.CoinData and true or false
    if currentProduct.CoinData then
        coinsButton:SetText(StringUtil.commaValue(currentProduct.CoinData.Cost), true)

        local canAfford = currentProduct.CoinData.Cost <= CurrencyController.getCoins()
        coinsButton:SetColor(canAfford and UIConstants.Colors.Buttons.AvailableGreen or UIConstants.Colors.Buttons.UnavailableGrey, true)
    end

    screenGui.Enabled = true
end

function ResultsScreen.close()
    screenGui.Enabled = false
end

return ResultsScreen
