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
local CoreGui = require(Paths.Client.UI.CoreGui)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)

local SHOW_STATE_MACHINE_DEBUG = true

local stateMachine = StateMachine.new(TableUtil.toArray(UIConstants.States), UIConstants.States.HUD)

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

    -- Toggle CoreGui
    stateMachine:RegisterGlobalCallback(function(_fromState: string, _toState: string)
        for _, enableState in pairs(UIConstants.EnableCoreGuiInStates) do
            if UIUtil.getPseudoState(enableState) then
                CoreGui.enable()
                return
            end
        end

        CoreGui.disable()
    end)
end

function UIController.getStateMachine()
    return stateMachine
end

function UIController.Start()
    -- Init Screens (any ModuleScript inside Screens with "Screen" in its name)
    do
        local screens = Paths.Client.UI.Screens
        local startMethods: { () -> nil } = {}
        for _, instance in pairs(screens:GetDescendants()) do
            local isScreenScript = instance:IsA("ModuleScript") and string.find(instance.Name, "Screen")
            if isScreenScript then
                local requiredScreen = require(instance)
                if requiredScreen.Init then
                    requiredScreen.Init()
                end
                if requiredScreen.Start then
                    table.insert(startMethods, requiredScreen.Start)
                end
            end
        end

        for _, startMethod in pairs(startMethods) do
            task.spawn(startMethod)
        end
    end
end

return UIController
