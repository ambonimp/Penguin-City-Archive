--[[
    sp = Single player
    mp = Multiplayer
]]

local SledRaceScreen = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Images = require(Paths.Shared.Images.Images)
local Remotes = require(Paths.Shared.Remotes)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local MinigameController = require(Paths.Client.Minigames.MinigameController)

local EXIT_BUTTON_TEXT = "Go Back"
local INSTRUCTIONS_BUTTON_TEXT = "Instructions"

local COUNTDOWN_TWEEN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local COUNTDOWN_BIND_KEY = "Coundown"
-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local uiStateMachine = UIController.getStateMachine()

local screen: ScreenGui = Paths.UI.Minigames.SledRace
local backdrop: Frame = screen.Backdrop
local instructionsFrame: Frame = screen.Instructions
local spStartFrame: Frame = screen.SinglePlayerStart

local countdown: ImageLabel = screen.Countdown
local countdownSize: UDim2 = countdown.Size

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function SledRaceScreen.openStart()
    if MinigameController.isMultiplayer() then
        MinigameController.SinglePlayerStart = false
    else
        backdrop.Visible = true
        spStartFrame.Visible = true
        ScreenUtil.openBlur()
    end
end

function SledRaceScreen.closeStart()
    if MinigameController.isMultiplayer() then
    else
        backdrop.Visible = false
        spStartFrame.Visible = false
        ScreenUtil.closeBlur()
    end
end

function SledRaceScreen.countdown(timeLeft: number)
    countdown.Visible = false
    countdown.Image = Images.SledRace["Countdown" .. (timeLeft - 1)]
    countdown.Rotation = 90
    countdown.Size = UDim2.new()

    countdown.Visible = true
    TweenUtil.bind(
        countdown,
        COUNTDOWN_BIND_KEY,
        TweenService:Create(countdown, COUNTDOWN_TWEEN_INFO, { Rotation = 0, Size = countdownSize })
    ).Completed
        :Connect(function(playbackState)
            -- RETURN: Previous tween was cancelled
            if playbackState ~= Enum.PlaybackState.Completed then
                return
            end

            TweenUtil.bind(
                countdown,
                COUNTDOWN_BIND_KEY,
                TweenService:Create(countdown, COUNTDOWN_TWEEN_INFO, {
                    Rotation = 90,
                    Size = UDim2.new(),
                })
            )
        end)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
-- Single player start
do
    spStartFrame.Play.MouseButton1Down:Connect(function()
        Remotes.fireServer("MinigameStarted")
    end)

    local exitButton = KeyboardButton.new()
    exitButton:SetColor(UIConstants.Colors.Buttons.CloseRed, true)
    exitButton:SetText(EXIT_BUTTON_TEXT, true)
    exitButton:Mount(spStartFrame.Actions.Exit, true)
    exitButton:SetIcon(Images.Icons.Exit)
    exitButton:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
    exitButton.InternalRelease:Connect(function()
        Remotes.fireServer("MinigameExited")
        SledRaceScreen.closeStart()
    end)

    local instructionsButton = KeyboardButton.new()
    instructionsButton:SetColor(UIConstants.Colors.Buttons.InstructionsOrange, true)
    instructionsButton:SetText(INSTRUCTIONS_BUTTON_TEXT, true)
    instructionsButton:Mount(spStartFrame.Actions.Instructions, true)
    instructionsButton:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
    instructionsButton:SetIcon(Images.Icons.Instructions)
    instructionsButton.InternalRelease:Connect(function()
        spStartFrame.Visible = false
        ScreenUtil.inUp(instructionsFrame)
    end)
end

-- Instructions
do
    local exitButton = ExitButton.new()
    exitButton.Pressed:Connect(function()
        ScreenUtil.outDown(instructionsFrame)
        if not MinigameController.isMultiplayer() then
            spStartFrame.Visible = true
        end
    end)
    exitButton:Mount(instructionsFrame.Exit, true)
end

-- UI States
uiStateMachine:RegisterStateCallbacks(UIConstants.States.Minigame, function()
    if MinigameController.getMinigame() == "SledRace" then
        SledRaceScreen.openStart()
    end
end, function()
    if MinigameController.getMinigame() == "SledRace" then
        SledRaceScreen.closeStart()
    end
end)

return SledRaceScreen
