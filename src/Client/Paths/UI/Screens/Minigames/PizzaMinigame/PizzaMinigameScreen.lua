local PizzaMinigameScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local Button = require(Paths.Client.UI.Elements.Button)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local Images = require(Paths.Shared.Images.Images)
local DeviceUtil = require(Paths.Client.Utils.DeviceUtil)

local EXIT_BUTTON_TEXT = "Go Back"
local INSTRUCTIONS_BUTTON_TEXT = "Instructions"

local screenGui: ScreenGui = Ui.Minigames.PizzaMinigame
local menuFrame: ImageButton = screenGui.Menu
local gameplayFrame: Frame = screenGui.Gameplay
local menuButtonsFrame: Frame = menuFrame.Buttons
local instructionsFrame: Frame = screenGui.Instructions
local playButton = Button.new(menuFrame)
local exitButton = KeyboardButton.new()
local instructionsButton = KeyboardButton.new()
local exitGameplayButton = KeyboardButton.new()
local instructionsCloseButton = KeyboardButton.new()

function PizzaMinigameScreen.Init()
    -- Setup Buttons
    do
        playButton:SetPressedDebounce(UIConstants.DefaultButtonDebounce)

        exitButton:SetColor(UIConstants.Colors.Buttons.CloseRed, true)
        exitButton:SetText(EXIT_BUTTON_TEXT, true)
        exitButton:Mount(menuButtonsFrame.Exit, true)
        exitButton:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
        exitButton:SetIcon(Images.Icons.Exit)

        instructionsButton:SetColor(UIConstants.Colors.Buttons.InstructionsOrange, true)
        instructionsButton:SetText(INSTRUCTIONS_BUTTON_TEXT, true)
        instructionsButton:Mount(menuButtonsFrame.Instructions, true)
        instructionsButton:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
        instructionsButton:SetIcon(Images.Icons.Instructions)

        exitGameplayButton:SetColor(UIConstants.Colors.Buttons.CloseRed, true)
        exitGameplayButton:SetText(EXIT_BUTTON_TEXT, true)
        exitGameplayButton:Mount(gameplayFrame.ExitButton, true)
        exitGameplayButton:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
        exitGameplayButton:SetIcon(Images.Icons.Exit)
        UIUtil.offsetGuiInset(gameplayFrame.ExitButton)

        instructionsCloseButton:SetColor(UIConstants.Colors.Buttons.CloseRed)
        instructionsCloseButton:SetIcon(Images.Icons.Close)
        instructionsCloseButton:Mount(instructionsFrame.Background.CloseButton, true)
        instructionsCloseButton:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
        instructionsCloseButton:RoundOff()
        instructionsCloseButton:Outline(UIConstants.Offsets.ButtonOutlineThickness, Color3.fromRGB(255, 255, 255))
    end

    -- Register UIState
    UIController.registerStateScreenCallbacks(UIConstants.States.PizzaMinigame, {
        Boot = nil,
        Shutdown = nil,
        Maximize = PizzaMinigameScreen.maximize,
        Minimize = PizzaMinigameScreen.minimize,
    })

    -- Customise TapToPlayText by device
    menuFrame.TapToPlay.Text = ("%s TO PLAY"):format(DeviceUtil.isMobile() and "TAP" or "CLICK")
end

-------------------------------------------------------------------------------
-- Getters
-------------------------------------------------------------------------------

function PizzaMinigameScreen.getPlayButton()
    return playButton
end

function PizzaMinigameScreen.getExitButton()
    return exitButton
end

function PizzaMinigameScreen.getExitGameplayButton()
    return exitGameplayButton
end

function PizzaMinigameScreen.getInstructionsButton()
    return instructionsButton
end

function PizzaMinigameScreen.getInstructionsCloseButton()
    return instructionsCloseButton
end

-------------------------------------------------------------------------------
-- Actions
-------------------------------------------------------------------------------

function PizzaMinigameScreen.maximize()
    screenGui.Enabled = true
end

function PizzaMinigameScreen.minimize()
    screenGui.Enabled = false
end

function PizzaMinigameScreen.viewMenu()
    menuFrame.Visible = true
    gameplayFrame.Visible = false
    instructionsFrame.Visible = false
end

function PizzaMinigameScreen.viewGameplay()
    menuFrame.Visible = false
    gameplayFrame.Visible = true
    instructionsFrame.Visible = false
end

function PizzaMinigameScreen.viewInstructions()
    menuFrame.Visible = false
    gameplayFrame.Visible = false
    instructionsFrame.Visible = true
end

return PizzaMinigameScreen
