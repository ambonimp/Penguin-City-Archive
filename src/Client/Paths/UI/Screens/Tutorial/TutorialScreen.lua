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
local TutorialController = require(Paths.Client.Tutorial.TutorialController)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local Images = require(Paths.Shared.Images.Images)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local HUDScreen = require(Paths.Client.UI.Screens.HUD.HUDScreen)
local Sound = require(Paths.Shared.Sound)

local PET_EGG_TWEEN_INFO_GROW_IN = TweenInfo.new(0.7)
local PET_EGG_DISPLAY_WAIT = 2
local PET_EGG_TWEEN_INFO_INTO_BACKPACK = TweenInfo.new(1, Enum.EasingStyle.Linear)

local screenGui: ScreenGui = Paths.UI.Tutorial
local skipButtonFrame: Frame = screenGui.SkipButton
local promptFrame: Frame = screenGui.Prompt
local bodyLabel: TextLabel = promptFrame.TextLabel
local nextButtonFrame: Frame = promptFrame.NextButton
local petEggImageLabel: ImageLabel = screenGui.PetEgg

local skipButton = KeyboardButton.new()
local nextButton = KeyboardButton.new()
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
            UIActions.prompt("Skip Tutorial", "Are you sure you want to skip the tutorial?", nil, {
                Text = "Skip",
                Callback = TutorialController.skipTutorial,
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

function TutorialScreen.boot()
    -- Hide stuff by default
    ScreenUtil.outDown(promptFrame)
    petEggImageLabel.Visible = false
end

function TutorialScreen.shutdown()
    -- Ensure prompt is somewhat cleaned up
    nextButton.Pressed:Fire() -- hacky solution but works
    isShowingPrompt = false
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
function TutorialScreen.prompt(promptText: string)
    local nextPrompt = Queue.yield("TutorialScreen.prompt")

    -- Update State + text
    isShowingPrompt = true
    bodyLabel.Text = promptText

    -- Enter Screen
    ScreenUtil.inUp(promptFrame)

    -- YIELD: Wait for next to be pressed
    nextButton.Pressed:Wait()
    task.wait() -- Need this here to stop .Pressed propogating to the next `prompt` call

    -- Exit Screen
    ScreenUtil.outDown(promptFrame)

    -- Update State + Queue
    isShowingPrompt = false
    nextPrompt()
end

--[[
    Displays a pet egg onto the screen, then tweens it into the inventory HUD button.

    Yields until process is done.

    https://bit.ly/3WhLKmK
]]
function TutorialScreen.egg(petEggName: string)
    local nextEgg = Queue.yield("TutorialScreen.egg")

    -- Populate ImageLabel
    local petEggproduct = ProductUtil.getPetEggProduct(petEggName)
    petEggImageLabel.Image = petEggproduct.ImageId or Images.Pets.Eggs.Standard
    petEggImageLabel.ImageColor3 = petEggproduct.ImageColor or Color3.fromRGB(255, 255, 255)

    -- Audio Feedback
    Sound.play("SparkleReveal")

    -- Tween ImageLabel
    do
        -- Read State
        local startingSize = petEggImageLabel.Size
        local startingPosition = petEggImageLabel.Position

        -- Set to 0
        petEggImageLabel.Size = UDim2.fromScale(0, 0)
        petEggImageLabel.Visible = true

        -- Grow in
        TweenUtil.tween(petEggImageLabel, PET_EGG_TWEEN_INFO_GROW_IN, {
            Size = startingSize,
        })
        task.wait(PET_EGG_TWEEN_INFO_GROW_IN.Time)

        -- Wait
        task.wait(PET_EGG_DISPLAY_WAIT)

        -- Shrink into inventory
        local inventoryButton: ImageButton = HUDScreen.getInventoryButton():GetButtonObject()
        local inventoryPosition = inventoryButton.AbsolutePosition + inventoryButton.AbsoluteSize / 2

        TweenUtil.tween(petEggImageLabel, PET_EGG_TWEEN_INFO_INTO_BACKPACK, {
            Size = UDim2.fromScale(0, 0),
            Position = UDim2.fromOffset(inventoryPosition.X, inventoryPosition.Y),
        })
        task.wait(PET_EGG_TWEEN_INFO_INTO_BACKPACK.Time)

        -- Reset
        petEggImageLabel.Visible = false
        petEggImageLabel.Size = startingSize
        petEggImageLabel.Position = startingPosition
    end

    nextEgg()
end

return TutorialScreen
