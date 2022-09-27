local PizzaMinigameScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local Button = require(Paths.Client.UI.Elements.Button)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)

local PLAY_BUTTON_TEXT = "Play Pizza"
local INSTRUCTIONS_BUTTON_TEXT = "Instructions"
local DEBOUNCE_TIME = 0.2

local screenGui: ScreenGui = Ui.Minigames.PizzaMinigame
local buttonsFrame: Frame = screenGui.Buttons
local playButton = Button.new()
local instructionsButton = Button.new()

function PizzaMinigameScreen.Init()
    -- Setup Buttons
    do
        playButton:SetColor(UIConstants.Colors.Buttons.PlayGreen, true)
        playButton:SetText(PLAY_BUTTON_TEXT, true)
        playButton:Mount(buttonsFrame.Play, true)
        playButton:SetPressedDebounce(DEBOUNCE_TIME)

        instructionsButton:SetColor(UIConstants.Colors.Buttons.InstructionsOrange, true)
        instructionsButton:SetText(INSTRUCTIONS_BUTTON_TEXT, true)
        instructionsButton:Mount(buttonsFrame.Instructions, true)
        instructionsButton:SetPressedDebounce(DEBOUNCE_TIME)
    end

    -- Register UIState
    do
        local function enter()
            PizzaMinigameScreen.open()
        end

        local function exit()
            PizzaMinigameScreen.close()
        end

        UIController.getStateMachine():RegisterStateCallbacks(UIConstants.States.PizzaMinigame, enter, exit)
    end
end

-------------------------------------------------------------------------------
-- Getters
-------------------------------------------------------------------------------

function PizzaMinigameScreen.getPlayButton()
    return playButton
end

function PizzaMinigameScreen.getInstructionsButton()
    return instructionsButton
end

-------------------------------------------------------------------------------
-- Actions
-------------------------------------------------------------------------------

function PizzaMinigameScreen.open()
    screenGui.Enabled = true
end

function PizzaMinigameScreen.close()
    screenGui.Enabled = false
end

function PizzaMinigameScreen.viewMenu()
    buttonsFrame.Visible = true
end

function PizzaMinigameScreen.viewGameplay()
    buttonsFrame.Visible = false
end

return PizzaMinigameScreen
