local GenericPromptScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Packages.maid)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)

local BACKGROUND_ROTATE_TWEEN_INFO = TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, math.huge)

local screenGui: ScreenGui = Ui.GenericPrompt
local contents: Frame = screenGui.Back.Contents
local titleLabel: TextLabel = contents.Text.Title
local descriptionLabel: TextLabel = contents.Text.Description
local leftButtonFrame: Frame = contents.Buttons.Left
local rightButtonFrame: Frame = contents.Buttons.Right
local middleFrame: Frame = contents.Middle
local closeButtonFrame: Frame = screenGui.Back.CloseButton
local backgroundFrame: ImageLabel = screenGui.Background

local leftButton = KeyboardButton.new()
local rightButton = KeyboardButton.new()
local closeButton = ExitButton.new()

local openMaid = Maid.new()

GenericPromptScreen.Defaults = {
    LeftButton = {
        Text = "Cancel",
        Color = Color3.fromRGB(250, 178, 92),
    },
    RightButton = {
        Text = "Continue",
        Color = Color3.fromRGB(50, 195, 127),
    },
}

function GenericPromptScreen.Init()
    local function exitState()
        UIController.getStateMachine():Remove(UIConstants.States.GenericPrompt)
    end

    -- Buttons
    do
        leftButton:Mount(leftButtonFrame, true)
        leftButton.Pressed:Connect(exitState)

        rightButton:Mount(rightButtonFrame, true)
        rightButton.Pressed:Connect(exitState)

        closeButton:Mount(closeButtonFrame, true)
        closeButton.Pressed:Connect(exitState)
    end

    -- Register UIState
    UIController.registerStateScreenCallbacks(UIConstants.States.GenericPrompt, {
        Boot = GenericPromptScreen.boot,
        Shutdown = GenericPromptScreen.shutdown,
        Maximize = GenericPromptScreen.maximize,
        Minimize = GenericPromptScreen.minimize,
    })
end

function GenericPromptScreen.boot(data: table)
    local title: string? = data.Title
    local description: string? = data.Description
    local middleMounter: ((parent: GuiObject, maid: typeof(Maid.new())) -> nil)? = data.MiddleMounter
    local leftButtonData: { Text: string?, Icon: string?, Color: Color3?, Callback: (() -> nil)? }? = data.LeftButton
    local rightButtonData: { Text: string?, Icon: string?, Color: Color3?, Callback: (() -> nil)? }? = data.LeftButton
    local background: { Blur: boolean?, Image: string?, DoRotate: boolean? }? = data.Background

    titleLabel.Text = title or "Title"
    descriptionLabel.Text = description or "Description"

    if middleMounter then
        middleMounter(middleFrame, openMaid)
    end

    leftButtonData = leftButtonData or {}
    leftButton:SetText(leftButtonData.Text or GenericPromptScreen.Defaults.LeftButton.Text)
    leftButton:SetIcon(leftButtonData.Icon or "")
    leftButton:SetColor(leftButtonData.Color or GenericPromptScreen.Defaults.LeftButton.Color)
    if leftButtonData.Callback then
        openMaid:GiveTask(leftButton.Pressed:Connect(leftButtonData.Callback))
    end

    rightButtonData = rightButtonData or {}
    rightButton:SetText(rightButtonData.Text or GenericPromptScreen.Defaults.RightButton.Text)
    rightButton:SetIcon(rightButtonData.Icon or "")
    rightButton:SetColor(rightButtonData.Color or GenericPromptScreen.Defaults.RightButton.Color)
    if rightButtonData.Callback then
        openMaid:GiveTask(rightButton.Pressed:Connect(rightButtonData.Callback))
    end

    if background then
        backgroundFrame.Visible = true
        backgroundFrame.BackgroundTransparency = background.Blur and 0.5 or 1
        backgroundFrame.Image = background.Image or ""
        backgroundFrame.Rotation = 0

        if background.DoRotate then
            local tween = TweenUtil.tween(backgroundFrame, BACKGROUND_ROTATE_TWEEN_INFO, {
                Rotation = 360,
            })
            openMaid:GiveTask(function()
                tween:Cancel()
                tween:Destroy()
            end)
        end
    else
        backgroundFrame.Visible = false
    end
end

function GenericPromptScreen.shutdown()
    openMaid:Cleanup()
end

function GenericPromptScreen.maximize()
    ScreenUtil.inDown(screenGui.Back)
    ScreenUtil.inDown(backgroundFrame)
    screenGui.Enabled = true
end

function GenericPromptScreen.minimize()
    ScreenUtil.outUp(screenGui.Back)
    ScreenUtil.outUp(backgroundFrame)
end

return GenericPromptScreen
