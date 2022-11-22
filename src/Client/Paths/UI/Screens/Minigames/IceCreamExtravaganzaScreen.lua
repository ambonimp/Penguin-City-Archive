local IceCreamExtravaganzaScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local SharedMinigameScreen = require(Paths.Client.UI.Screens.Minigames.SharedMinigameScreen)

local screenGui: ScreenGui = Paths.UI.Minigames.IceCreamExtravaganza
local instructionsFrame: Frame = screenGui.Instructions

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

return IceCreamExtravaganzaScreen
