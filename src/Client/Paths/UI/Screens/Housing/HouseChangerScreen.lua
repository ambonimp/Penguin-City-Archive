local HouseChangerScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local BlueprintConstants = require(Paths.Shared.Constants.HouseObjects.BlueprintConstants)
local Remotes = require(Paths.Shared.Remotes)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local Widget = require(Paths.Client.UI.Elements.Widget)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)

local screenGui: ScreenGui = Paths.UI.ChangeHouse
local frame: Frame = screenGui.ChangeHouse

local uiStateMachine = UIController.getStateMachine()

local HOUSE_WIDGET_SIZE = UDim2.new(0.65, 0, 0, 267)

local plotAt: Model

-- Register UIState
do
    local function boot(data)
        screenGui.Enabled = true
        plotAt = data.PlotAt

        ScreenUtil.sizeIn(frame)
    end

    local function shutdown()
        ScreenUtil.sizeOut(frame)
    end

    local function maximize()
        ScreenUtil.sizeIn(frame)
    end

    local function minimize()
        ScreenUtil.sizeOut(frame)
    end

    --uiStateMachine:RegisterStateCallbacks(UIConstants.States.HouseSelectionUI, open, close)
    UIController.registerStateScreenCallbacks(UIConstants.States.HouseSelectionUI, {
        Boot = boot,
        Shutdown = shutdown,
        Maximize = maximize,
        Minimize = minimize,
    })
end

-- Manipulate UIState
do
    local exitButton = ExitButton.new(UIConstants.States.HouseSelectionUI)
    exitButton.Pressed:Connect(function()
        uiStateMachine:PopTo(UIConstants.States.HUD)
    end)
    exitButton:Mount(frame.ExitButton, true)
end

do --Add House products
    for name, _info in BlueprintConstants.Objects do
        local product = ProductUtil.getProduct("HouseObject", ProductUtil.getBlueprintProductId("Blueprint", name))
        local widget = Widget.diverseWidgetFromProduct(product, { VerifyOwnership = true }, function(button)
            button.Pressed:Connect(function()
                uiStateMachine:PopTo(UIConstants.States.HUD)
                Remotes.fireServer("ChangeBlueprint", name)
            end)
        end)

        widget:GetGuiObject().LayoutOrder = product.CoinData.Cost
        widget:GetGuiObject().Parent = frame.Center.Houses
        widget:SetSize(HOUSE_WIDGET_SIZE)
    end
end

return HouseChangerScreen
