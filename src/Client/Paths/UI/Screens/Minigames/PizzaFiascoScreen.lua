local PizzaFiascoScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Images = require(Paths.Shared.Images.Images)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local UIConstants = require(Paths.Client.UI.UIConstants)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local SharedMinigameScreen = require(Paths.Client.UI.Screens.Minigames.SharedMinigameScreen)

local screenGui: ScreenGui = Paths.UI.Minigames.PizzaFiasco
local gameplayFrame: Frame = screenGui.Gameplay
local instructionsFrame: Frame = screenGui.Instructions

local EXIT_BUTTON_TEXT = "Go Back"

-------------------------------------------------------------------------------
-- Actions
-------------------------------------------------------------------------------
function PizzaFiascoScreen.viewGameplay()
    gameplayFrame.Visible = true
end

function PizzaFiascoScreen.closeGameplay()
    gameplayFrame.Visible = false
end

-------------------------------------------------------------------------------
-- Buttons Set up
-------------------------------------------------------------------------------
do
    local exitButton = ExitButton.new()
    exitButton.Pressed:Connect(function()
        ScreenUtil.outDown(instructionsFrame)
        SharedMinigameScreen.openStartMenu()
    end)
    exitButton:Mount(instructionsFrame.Exit, true)
end
--[[
do
    local exitGameplayButton = KeyboardButton.new()
    exitGameplayButton:SetColor(UIConstants.Colors.Buttons.CloseRed, true)
    exitGameplayButton:SetText(EXIT_BUTTON_TEXT, true)
    exitGameplayButton:Mount(gameplayFrame.ExitButton, true)
    exitGameplayButton:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
    exitGameplayButton:SetIcon(Images.Icons.Exit)
end
 *]]
return PizzaFiascoScreen
