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
local Signal = require(Paths.Shared.Signal)

local SHOW_STATE_MACHINE_DEBUG = false

UIController.StateBooted = Signal.new() -- { state: string }
UIController.StateShutdown = Signal.new() -- { state: string }
UIController.StateMaximized = Signal.new() -- { state: string }
UIController.StateMinimized = Signal.new() -- { state: string }

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
local stateCloseCallbacks: { [string]: { () -> nil } } = {}

-- Init
do
    stateMachine:SetDebugPrintingEnabled(SHOW_STATE_MACHINE_DEBUG)

    -- Listen to StateCloseCallback (e.g., XBOX closing a menu using B)
    UserInputService.InputEnded:Connect(function(inputObject, gameProcessedEvent)
        -- RETURN: Game Processed
        if gameProcessedEvent then
            return
        end

        -- Should we run a callback?
        local isStateCloseCallbackKeybind = table.find(UIConstants.Keybinds.StateCloseCallback, inputObject.KeyCode)
        if isStateCloseCallbackKeybind then
            local callbacks = stateCloseCallbacks[UIController.getStateMachine():GetState()]
            if callbacks then
                for _, callback in pairs(callbacks) do
                    callback()
                end
            end
        end
    end)

    -- Manage State Callbacks
    stateMachine:RegisterGlobalCallback(function(_fromState: string, _toState: string, data: table?)
        -- Iterate screenData
        for someState, screenData in pairs(stateScreenData) do
            -- Check if we are on top or not
            local isOnTop = UIController.isStateMaximized(someState)

            -- Run Logic

            -- Shutdown and Minimize
            if not isOnTop then
                if screenData.Meta.IsBooted then
                    local isRemoved = stateMachine:HasState(someState) == false
                    if isRemoved then
                        screenData.Meta.IsBooted = false
                        if screenData.Callbacks.Shutdown then
                            screenData.Callbacks.Shutdown()
                            UIController.StateShutdown:Fire(someState)
                            --print(someState, "Shutdown")
                        end
                    end
                end

                if screenData.Meta.IsMaximized then
                    screenData.Meta.IsMaximized = false
                    if screenData.Callbacks.Minimize then
                        screenData.Callbacks.Minimize()
                        UIController.StateMinimized:Fire(someState)
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
                        UIController.StateBooted:Fire(someState)
                        --print(someState, "Boot")
                    end
                end

                if not screenData.Meta.IsMaximized then
                    screenData.Meta.IsMaximized = true
                    if screenData.Callbacks.Maximize then
                        screenData.Callbacks.Maximize()
                        UIController.StateMaximized:Fire(someState)
                        --print(someState, "Maximize")
                    end
                end
            end
        end
    end)

    -- Toggle CoreGui
    stateMachine:RegisterGlobalCallback(function(_fromState: string, _toState: string)
        task.wait() -- Give other RegisterGlobalCallback callbacks time to breathe + update so our `isStateMaximized` call works as intended

        for _, enableState in pairs(UIConstants.EnableCoreGuiInStates) do
            if UIController.isStateMaximized(enableState) then
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

-- Queries the current stack and our UIConstants to make a decision
function UIController.isStateMaximized(state: string)
    -- Manage Invisible States: Get a list of invisible states on the top, and as such the "visible" state on top!
    local currentStack = stateMachine:GetStack()
    local topState: string?
    local invisibleStates: { string } = {}
    for i = #currentStack, 1, -1 do
        local someState = currentStack[i]
        local isInvisible = table.find(UIConstants.InvisibleStates, someState) and true or false
        if isInvisible then
            table.insert(invisibleStates, someState)
        else
            topState = someState
            break
        end
    end

    -- Check if we are visible or not
    local isInvisible = table.find(invisibleStates, state)
    local isMaximized = isInvisible or UIUtil.getPseudoState(state, topState)

    return isMaximized
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
        Boot: ((data: table?) -> nil)?,
        Shutdown: (() -> nil)?,
        Maximize: (() -> nil)?,
        Minimize: (() -> nil)?,
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

--[[
    Binds a callback to when the user requests a generic "close" when in a UIState.

    This is how we get our XBOX "B" close behaviour!
]]
function UIController.registerStateCloseCallback(state: string, callback: () -> nil)
    stateCloseCallbacks[state] = stateCloseCallbacks[state] or {}

    table.insert(stateCloseCallbacks[state], callback)
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
