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
local stateScreenData: {
    [string]: {
        Callbacks: {
            Boot: ((data: table?) -> nil) | nil,
            Shutdown: (() -> nil) | nil,
            Maximize: (() -> nil) | nil,
            Minimize: (() -> nil) | nil,
        },
        Meta: {
            IsBooted: boolean,
            IsMaximized: boolean,
        },
    },
} =
    {}

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

    -- Manage State Callbacks
    stateMachine:RegisterGlobalCallback(function(_fromState: string, toState: string, data: table?, oldStack: { string })
        -- Iterate each callback
        for someState, screenData in pairs(stateScreenData) do
            -- Check if we are on top or not
            local isInvisible = table.find(UIConstants.InvisibleStates, someState) and true or false
            local isOnTop = not isInvisible and (toState == someState or UIUtil.getPseudoState(someState))

            -- Custom UIConstants Behaviour
            if not isOnTop then
                -- Check if states above us are "invisible"
                local statesAbove = stateMachine:GetStatesAbove(someState)
                if statesAbove then
                    local allInvisible = true
                    for _, aboveState in pairs(statesAbove) do
                        if not table.find(UIConstants.InvisibleStates, aboveState) then
                            allInvisible = false
                            break
                        end
                    end
                    isOnTop = allInvisible
                end
            end

            -- Shutdown and Minimize
            if not isOnTop then
                if screenData.Meta.IsBooted then
                    local isRemoved = stateMachine:HasState(someState) == false
                    if isRemoved then
                        screenData.Meta.IsBooted = false
                        if screenData.Callbacks.Shutdown then
                            screenData.Callbacks.Shutdown()
                            --print(someState, "Shutdown")
                        end
                    end
                end

                if screenData.Meta.IsMaximized then
                    screenData.Meta.IsMaximized = false
                    if screenData.Callbacks.Minimize then
                        screenData.Callbacks.Minimize()
                        --print(someState, "Minimize")
                    end
                end
            end

            -- Boot and maximize
            if isOnTop then
                if not screenData.Meta.IsBooted then
                    screenData.Meta.IsBooted = true
                    if screenData.Callbacks.Boot then
                        screenData.Callbacks.Boot(data)
                        --print(someState, "Boot")
                    end
                end

                if not screenData.Meta.IsMaximized then
                    screenData.Meta.IsMaximized = true
                    if screenData.Callbacks.Maximize then
                        screenData.Callbacks.Maximize()
                        --print(someState, "Maximize")
                    end
                end
            end
        end
    end)
end

function UIController.getStateMachine()
    return stateMachine
end

--[[
    A powerful method for interfacing with the UI State machine, which considers custom behaviour defined in our UIConstants

    - `Boot`: Called when the state first enters the stack
    - `Shutdown`: Called when the state is removed from the stack
    - `Maximize`: Called when the state is on the top of the stack
    - `Minimize`: Called when the state is no longer on top of the stack

    `Boot` and `Shutdown` are for initializing a UI screen, or cleaning it up. `Maximize` and `Minimize` are for visually showing/hiding the screen
    - Example: The InventoryScreen opens up a product prompt by pushing a state to the stack. When we return to the inventory to the top, it reopens it
    while still retaining it's current tab, as we `Minimize/Maximize`- and don't `Shutdown`
]]
function UIController.registerStateScreenCallbacks(
    state: string,
    callbacks: {
        Boot: (data: table?) -> nil,
        Shutdown: () -> nil,
        Maximize: () -> nil,
        Minimize: () -> nil,
    }
)
    -- ERROR: Already registered
    if stateScreenData[state] then
        error(("Already registered %q"):format(state))
    end

    stateScreenData[state] = {
        Callbacks = callbacks,
        Meta = {
            IsBooted = false,
            IsMaximized = false,
        },
    }
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
