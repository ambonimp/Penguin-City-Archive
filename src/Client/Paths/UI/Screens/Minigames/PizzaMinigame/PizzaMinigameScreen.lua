local PizzaMinigameScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Modules = Paths.Modules
local Ui = Paths.UI
local Button = require(Modules.UI.Elements.Button)
local UIConstants = require(Modules.UI.UIConstants)

local PLAY_BUTTON_TEXT = "Play Pizza"
local INSTRUCTIONS_BUTTON_TEXT = "Instructions"

local screenGui: ScreenGui = Ui.Minigames.Pizza
local buttonsFrame: Frame = screenGui.Buttons
local playButton = Button.new()
local instructionsButton = Button.new()

function PizzaMinigameScreen.Init()
    -- Setup Buttons
    do
        playButton:SetColor(UIConstants.Colors.Buttons.PlayGreen, true)
        playButton:SetText(PLAY_BUTTON_TEXT, true)
        playButton:Mount(buttonsFrame.Play)

        instructionsButton:SetColor(UIConstants.Colors.Buttons.InstructionsOrange, true)
        instructionsButton:SetText(INSTRUCTIONS_BUTTON_TEXT, true)
        instructionsButton:Mount(buttonsFrame.Instructions)
    end
end

return PizzaMinigameScreen
