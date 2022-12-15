local TutorialScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Packages.maid)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local UIConstants = require(Paths.Client.UI.UIConstants)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local UIActions = require(Paths.Client.UI.UIActions)
local Queue = require(Paths.Shared.Queue)

local screenGui: ScreenGui = Paths.UI.Tutorial
local skipButtonFrame: Frame = screenGui.SkipButton
local promptFrame: Frame = screenGui.Prompt
local bodyLabel: TextLabel = promptFrame.TextLabel
local nextButtonFrame: Frame = promptFrame.NextButton

local skipButton = KeyboardButton.new()
local nextButton = KeyboardButton.new()
local promptMaid = Maid.new()
local isShowingPrompt = false

-------------------------------------------------------------------------------
-- Internals
-------------------------------------------------------------------------------

function TutorialScreen.Init()
    -- Buttons
    do
        skipButton:SetText("Skip Tutorial")
        skipButton:SetColor(UIConstants.Colors.Buttons.EditOrange)
        skipButton:Mount(skipButtonFrame, true)
        skipButton.Pressed:Connect(function()
            warn("todo skip logic")
            UIActions.prompt("Skip Tutorial", "Are you sure you want to skip the tutorial?", nil, {
                Text = "Skip",
            }, {
                Text = "No, wait..",
            })
        end)

        nextButton:SetText("Next")
        nextButton:SetColor(UIConstants.Colors.Buttons.NextGreen)
        nextButton:Mount(nextButtonFrame, true)
    end

    -- Register UIState
    do
        UIController.registerStateScreenCallbacks(UIConstants.States.Tutorial, {
            Boot = TutorialScreen.boot,
            Shutdown = TutorialScreen.shutdown,
            Maximize = TutorialScreen.maximize,
            Minimize = TutorialScreen.minimize,
        })
    end
end

function TutorialScreen.boot(data: table?)
    -- Read Data

    --todo
end

function TutorialScreen.shutdown()
    --todo
end

function TutorialScreen.maximize()
    if isShowingPrompt then
        ScreenUtil.inUp(promptFrame)
    end
    ScreenUtil.inDown(skipButtonFrame)

    screenGui.Enabled = true
end

function TutorialScreen.minimize()
    if isShowingPrompt then
        ScreenUtil.outDown(promptFrame)
    end
    ScreenUtil.outUp(skipButtonFrame)
end

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------

-- Yields until prompt has been dismissed. Allows stacking of multiple calls
function TutorialScreen.prompt(body: string)
    local nextPrompt = Queue.yield("TutorialScreen.prompt")

    -- Update State + text
    isShowingPrompt = true
    bodyLabel.Text = body

    -- Enter Screen
    ScreenUtil.inUp(promptFrame)

    -- YIELD: Wait for next to be pressed
    nextButton.Pressed:Wait()

    -- Exit Screen
    ScreenUtil.outDown(promptFrame)

    -- Update State + Queue
    isShowingPrompt = false
    nextPrompt()
end

return TutorialScreen
