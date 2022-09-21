--[[
    This is the brain of the UI System
    ]]
local UIController = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = Paths.Modules.UIConstants
local TableUtil = Paths.Modules.TableUtil

local SHOW_STATE_MACHINE_DEBUG = true

local stateMachine = Paths.Modules.StateMachine.new(TableUtil.toArray(UIConstants.States), UIConstants.States.Nothing)

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

return UIController
