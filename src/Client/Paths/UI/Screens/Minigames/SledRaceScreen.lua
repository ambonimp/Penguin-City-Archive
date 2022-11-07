local SledRaceScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Images = require(Paths.Shared.Images.Images)
local Remotes = require(Paths.Shared.Remotes)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local MinigameScreenUtil = require(Paths.Client.UI.Screens.Minigames.MinigameScreenUtil)
local Transitions = require(Paths.Client.UI.Screens.SpecialEffects.Transitions)

local EXIT_BUTTON_TEXT = "Go Back"
local INSTRUCTIONS_BUTTON_TEXT = "Instructions"

local START_PAUSE_LENGTH = 0.3

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local player = Players.LocalPlayer

local screen: ScreenGui = Paths.UI.Minigames.SledRace
local instructionsFrame: Frame = screen.Instructions
local singlePlayerMenu: Frame = screen.SinglePlayerMenu

-------------------------------------------------------------------------------
-- Single player start
-------------------------------------------------------------------------------
do
    singlePlayerMenu.Play.MouseButton1Down:Connect(function()
        Transitions.blink(function()
            MinigameScreenUtil.closeMenu()
        end, { HalfTweenTime = 0.5 })

        task.wait(math.max(0, START_PAUSE_LENGTH - (player:GetNetworkPing() * 2)))
        print(math.max(0, START_PAUSE_LENGTH - (player:GetNetworkPing() * 2)))
        Remotes.fireServer("MinigameStarted")
    end)

    local exitButton = KeyboardButton.new()
    exitButton:SetColor(UIConstants.Colors.Buttons.CloseRed, true)
    exitButton:SetText(EXIT_BUTTON_TEXT, true)
    exitButton:Mount(singlePlayerMenu.Actions.Exit, true)
    exitButton:SetIcon(Images.Icons.Exit)
    exitButton:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
    exitButton.InternalRelease:Connect(function()
        Remotes.fireServer("MinigameExited")
        MinigameScreenUtil.closeMenu()
    end)

    local instructionsButton = KeyboardButton.new()
    instructionsButton:SetColor(UIConstants.Colors.Buttons.InstructionsOrange, true)
    instructionsButton:SetText(INSTRUCTIONS_BUTTON_TEXT, true)
    instructionsButton:Mount(singlePlayerMenu.Actions.Instructions, true)
    instructionsButton:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
    instructionsButton:SetIcon(Images.Icons.Instructions)
    instructionsButton.InternalRelease:Connect(function()
        singlePlayerMenu.Visible = false
        ScreenUtil.inUp(instructionsFrame)
    end)
end

-------------------------------------------------------------------------------
-- Instructions
-------------------------------------------------------------------------------
do
    local exitButton = ExitButton.new()
    exitButton.Pressed:Connect(function()
        ScreenUtil.outDown(instructionsFrame)
        if not MinigameController.isMultiplayer() then
            singlePlayerMenu.Visible = true
        end
    end)
    exitButton:Mount(instructionsFrame.Exit, true)
end

return SledRaceScreen
