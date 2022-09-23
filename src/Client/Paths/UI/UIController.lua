--[[
    This is the brain of the UI System
    ]]
local UIController = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local StateMachine = require(Paths.Shared.StateMachine)

local SHOW_STATE_MACHINE_DEBUG = true

local stateMachine = StateMachine.new(TableUtil.toArray(UIConstants.States), UIConstants.States.Nothing)
local ui: PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

-- Init
do
    stateMachine:SetDebugPrintingEnabled(SHOW_STATE_MACHINE_DEBUG)

    -- Listen to Pop keybinds (e.g., XBOX closing a menu using B)
    UserInputService.InputEnded:Connect(function(inputObject, gameProcessedEvent)
        -- RETURN: Game Processed
        if gameProcessedEvent then
            return
        end

        -- Should we pop?
        local isPopKeybind = table.find(UIConstants.Keybinds.PopStateMachine, inputObject.KeyCode)
        local isIgnoreState = table.find(UIConstants.DontPopStatesFromKeybind, stateMachine:GetState())
        if isPopKeybind and not isIgnoreState then
            stateMachine:Pop()
        end
    end)
end

function UIController.getStateMachine()
    return stateMachine
end

function UIController.getScreen(screen: string): ScreenGui
    return ui:WaitForChild(screen)
end

return UIController
