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

function UIController.Start()
    -- Init Screens (any ModuleScript inside Screens with "Screen" in its name)
    do
        local screens = Paths.Client.UI.Screens
        for _, instance in pairs(screens:GetDescendants()) do
            local isScreenScript = instance:IsA("ModuleScript") and string.find(instance.Name, "Screen")
            if isScreenScript then
                local requiredScreen = require(instance)
                if requiredScreen.Init then
                    requiredScreen.Init()
                end
            end
        end
    end
end

return UIController
