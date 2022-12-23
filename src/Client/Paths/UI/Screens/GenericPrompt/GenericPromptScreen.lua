local GenericPromptScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Shared.Maid)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)

local BACKGROUND_ROTATE_TWEEN_INFO = TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, math.huge)

local screenGui: ScreenGui = Ui.GenericPrompt
local backFrame: Frame = screenGui.Back
local contents: Frame = backFrame.Contents
local titleLabel: TextLabel = contents.Text.Title
local descriptionLabel: TextLabel = contents.Text.Description
local leftButtonFrame: Frame = contents.Buttons.Left
local rightButtonFrame: Frame = contents.Buttons.Right
local middleFrame: Frame = contents.Middle
local closeButtonFrame: Frame = backFrame.CloseButton
local backgroundFrame: ImageLabel = screenGui.Background

local leftButton = KeyboardButton.new()
local rightButton = KeyboardButton.new()
local closeButton = ExitButton.new(UIConstants.States.GenericPrompt)

local middleFrameSizeYOffset = middleFrame.Size.Y.Offset
local backFrameSize = backFrame.Size

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

local function exitState()
    UIController.getStateMachine():Remove(UIConstants.States.GenericPrompt)
end

function GenericPromptScreen.Init()
    -- Buttons
    do
        leftButton:Mount(leftButtonFrame, true)
        rightButton:Mount(rightButtonFrame, true)

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
    local middleMounter: ((parent: GuiObject, maid: Maid.Maid) -> nil)? = data.MiddleMounter
    local leftButtonData: { Text: string?, Icon: string?, Color: Color3?, Callback: (() -> nil)? }? = data.LeftButton
    local rightButtonData: { Text: string?, Icon: string?, Color: Color3?, Callback: (() -> nil)? }? = data.RightButton
    local background: { Blur: boolean?, Image: string?, DoRotate: boolean? }? = data.Background

    -- Title/Description
    titleLabel.Text = title or "Title"
    descriptionLabel.Text = description or "Description"

    -- Middle
    if middleMounter then
        middleFrame.Visible = true
        backFrame.Size = backFrameSize

        middleMounter(middleFrame, openMaid)
    else
        middleFrame.Visible = false
        backFrame.Size = backFrameSize - UDim2.fromOffset(0, middleFrameSizeYOffset)
    end

    leftButtonData = leftButtonData or {}
    leftButton:SetText(leftButtonData.Text or GenericPromptScreen.Defaults.LeftButton.Text)
    leftButton:SetIcon(leftButtonData.Icon or "")
    leftButton:SetColor(leftButtonData.Color or GenericPromptScreen.Defaults.LeftButton.Color)
    openMaid:GiveTask(leftButton.Pressed:Connect(function()
        exitState()

        if leftButtonData.Callback then
            leftButtonData.Callback()
        end
    end))

    rightButtonData = rightButtonData or {}
    rightButton:SetText(rightButtonData.Text or GenericPromptScreen.Defaults.RightButton.Text)
    rightButton:SetIcon(rightButtonData.Icon or "")
    rightButton:SetColor(rightButtonData.Color or GenericPromptScreen.Defaults.RightButton.Color)
    openMaid:GiveTask(rightButton.Pressed:Connect(function()
        exitState()

        if rightButtonData.Callback then
            rightButtonData.Callback()
        end
    end))

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
