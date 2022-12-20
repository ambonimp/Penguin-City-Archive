local EmotesScreen = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Shared.Maid)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local UIConstants = require(Paths.Client.UI.UIConstants)
local InputController = require(Paths.Client.Input.InputController)
local InputConstants = require(Paths.Client.Input.InputConstants)
local VectorUtil = require(Paths.Shared.Utils.VectorUtil)

local UP_VECTOR = Vector2.new(0, 1)

local uiStateMachine = UIController.getStateMachine()
local screenGui: ScreenGui = Paths.UI.Emotes
local menuFrame: Frame = screenGui.EmotesMenu
local bootMaid = Maid.new()

function EmotesScreen.Init()
    -- Register UIState
    do
        UIController.registerStateScreenCallbacks(UIConstants.States.Emotes, {
            Boot = EmotesScreen.boot,
            Shutdown = EmotesScreen.shutdown,
            Maximize = EmotesScreen.maximize,
            Minimize = EmotesScreen.minimize,
        })
    end

    -- Keybind to toggle
    do
        InputController.KeybindEnded:Connect(function(keybind: string, gameProcessedEvent: boolean)
            -- RETURN: Not a good event
            if not (keybind == "ToggleEmotes" and not gameProcessedEvent) then
                return
            end

            -- RETURN: Only run routine when we can see the HUD or see the Emotes screen
            if not (UIController.isStateMaximized(UIConstants.States.HUD) or UIController.isStateMaximized(UIConstants.States.Emotes)) then
                return
            end

            -- Toggle
            if uiStateMachine:HasState(UIConstants.States.Emotes) then
                uiStateMachine:Remove(UIConstants.States.Emotes)
            else
                uiStateMachine:Push(UIConstants.States.Emotes)
            end
        end)
    end
end

function EmotesScreen.boot()
    -- Read Data

    bootMaid:GiveTask(RunService.RenderStepped:Connect(function()
        local absoluteCenter = menuFrame.AbsolutePosition + menuFrame.AbsoluteSize / 2
        local mousePosition = UserInputService:GetMouseLocation()

        local absoluteCenterToMousePosition = mousePosition - absoluteCenter
        local angle = VectorUtil.getVector2FullAngle(UP_VECTOR, -absoluteCenterToMousePosition)

        print(absoluteCenter, "  ", mousePosition, " || ", absoluteCenterToMousePosition, "  ", angle)
    end))
end

function EmotesScreen.shutdown()
    bootMaid:Cleanup()
end

function EmotesScreen.maximize()
    ScreenUtil.inDown(menuFrame)
    screenGui.Enabled = true
end

function EmotesScreen.minimize()
    ScreenUtil.outUp(menuFrame)
end

return EmotesScreen
