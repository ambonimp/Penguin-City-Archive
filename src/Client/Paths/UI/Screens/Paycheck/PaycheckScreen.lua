local PaycheckScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local Maid = require(Paths.Packages.maid)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local TimeUtil = require(Paths.Shared.Utils.TimeUtil)
local RewardsConstants = require(Paths.Shared.Rewards.RewardsConstants)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local UIScaleController = require(Paths.Client.UI.Scaling.UIScaleController)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local Sound = require(Paths.Shared.Sound)

local ENTER_TWEEN_INFO_ROTATION = TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local ENTER_TWEEN_INFO_SCALE = TweenInfo.new(1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
local ENTER_ROTATE = 180

local screenGui: ScreenGui = Ui.Paycheck
local container: Frame = screenGui.Container
local uiScale: UIScale = container.UIScale
local cashoutButton = KeyboardButton.new()

local openMaid = Maid.new()

local fields: Frame = container.Paycheck.Fields
local contextDescription: TextLabel = fields.ContextDescription
local contextTitle: TextLabel = fields.ContextTitle
local nextPaycheck: TextLabel = fields.NextPaycheck
local numberValue: TextLabel = fields.NumberValue
local playerName: TextLabel = fields.PlayerName
local stringValue: TextLabel = fields.StringValue

function PaycheckScreen.Init()
    -- Buttons
    do
        cashoutButton:Mount(container.CashoutButton, true)
        cashoutButton:SetColor(UIConstants.Colors.Buttons.NextGreen)
        cashoutButton:SetText("Cashout!")
        cashoutButton.Pressed:Connect(function()
            UIController.getStateMachine():PopIfStateOnTop(UIConstants.States.Paycheck)
        end)
    end

    -- Register UIState
    do
        local function enter(data: table)
            PaycheckScreen.open(data)
        end

        local function exit()
            PaycheckScreen.close()
        end

        UIController.getStateMachine():RegisterStateCallbacks(UIConstants.States.Paycheck, enter, exit)
    end
end

function PaycheckScreen.open(data: table)
    -- Read Data
    local amount: number = data.Amount
    local totalPaychecks: number = data.TotalPaychecks
    if not (amount and totalPaychecks) then
        error("Bad Data")
    end

    -- Populate
    contextDescription.Text = ""
    contextTitle.Text = "Citizen Reward"
    nextPaycheck.Text = ("Next Paycheck in: <b>%s</b>"):format(TimeUtil.formatRelativeTime(RewardsConstants.Paycheck.EverySeconds - 1))
    numberValue.Text = StringUtil.commaValue(amount)
    playerName.Text = Players.LocalPlayer.DisplayName
    stringValue.Text = ("%s Only"):format(StringUtil.writtenNumber(amount))

    -- Grow + Spin in
    ScreenUtil.inDown(container)
    UIScaleController.updateUIScale(uiScale, 0)
    container.Rotation = ENTER_ROTATE
    screenGui.Enabled = true

    openMaid:GiveTask(TweenUtil.run(function(alpha)
        UIScaleController.updateUIScale(uiScale, UIScaleController.getScale() * alpha)
    end, ENTER_TWEEN_INFO_SCALE))
    openMaid:GiveTask(TweenUtil.run(function(alpha)
        container.Rotation = ENTER_ROTATE - (ENTER_ROTATE * alpha)
    end, ENTER_TWEEN_INFO_ROTATION))

    Sound.play("OpenGift")
end

function PaycheckScreen.close()
    openMaid:Cleanup()
    ScreenUtil.outUp(container)
    Sound.play("CashRegister")
end

return PaycheckScreen
