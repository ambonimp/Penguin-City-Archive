--[[
    Simple but powerful Finite State Machine implementation with state change callbacks and scheduling capabilities.
    ]]
local StateMachine = {}
StateMachine.__index = StateMachine

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Shared.Signal)

type Operation = string

export type StateMachine = typeof(StateMachine.new({}, ""))

local OPERATION_PUSH: Operation = "Push"
local OPERATION_REPLACE: Operation = "Replace"
local OPERATION_POP: Operation = "Pop"
local OPERATION_POP_TO: Operation = "PopTo"
local OPERATION_POP_TO_AND_PUSH: Operation = "PopToAndPush"
local OPERATION_CLEAR_AND_PUSH: Operation = "ClearAndPush"
local OPERATION_REMOVE: Operation = "Remove"
local SHOW_TRACEBACK_IN_DEBUG = false
local SHOW_DEBUG = false

local function prettyError(operation: string, state: string, append: string)
    error(("[StateMachine] Error during %s operation with %s state: %s"):format(operation, tostring(state), append), 3)
end

local function prettyDebug(...: string)
    if SHOW_DEBUG then
        print("[StateMachine]", ...)
    end
end

function StateMachine.new(states: { string }, initialState: string)
    -- ERROR: Needs atleast 1 state
    if #states == 0 then
        error("[StateMachine] Constructor needs atleast 1 state passed")
    end

    -- ERROR: Bad initial state
    initialState = initialState or states[1]
    if not (initialState and table.find(states, initialState)) then
        error("[StateMachine] Constructor not passed a valid initialState")
    end

    local self = {
        registeredStates = states,
        stateStack = { initialState },
        lastData = {},
        isDebugPrintingEnabled = false,
        eventGlobal = Signal.new(),
    }
    setmetatable(self, StateMachine)

    return self
end

--[[
    Internal function for changing state
]]
function StateMachine:_ChangeState(operation: Operation, state: string, popToIndex: number?)
    local isStateAlreadyAtTheTop = state == self:GetState()

    -- Push
    if OPERATION_PUSH == operation then
        if not isStateAlreadyAtTheTop then
            table.insert(self.stateStack, state)
        end
        return
    end

    -- Replace
    if OPERATION_REPLACE == operation then
        if not isStateAlreadyAtTheTop then
            self.stateStack[#self.stateStack] = state
        end
        return
    end

    -- Pop
    if OPERATION_POP == operation then
        self.stateStack[#self.stateStack] = nil
        return
    end

    -- PopTo and PopToAndPush
    if OPERATION_POP_TO == operation or OPERATION_POP_TO_AND_PUSH == operation then
        for i = #self.stateStack, math.max(1, popToIndex + 1), -1 do
            self.stateStack[i] = nil
        end

        -- Push state after popping
        if OPERATION_POP_TO_AND_PUSH == operation then
            if self:GetState() ~= state then
                self:_ChangeState(OPERATION_PUSH, state)
            end
        end
        return
    end

    -- ClearAndPush
    if OPERATION_CLEAR_AND_PUSH == operation then
        for i = #self.stateStack, 2, -1 do
            self.stateStack[i] = nil
        end

        -- Push state after clearing up
        self:_ChangeState(OPERATION_REPLACE, state)
        return
    end

    -- Remove
    if OPERATION_REMOVE == operation then
        -- If state is on top, just pop it
        if self:GetState() == state then
            self:_ChangeState(OPERATION_POP, state)
            return
        end

        -- If state is in the middle, extract it
        local index = table.find(self.stateStack, state)
        if index then
            table.remove(self.stateStack, index)
        end
    end
end

--[[
    Internal function for running large logic
]]
function StateMachine:_RunOperation(operation, state, data)
    task.defer(function() -- Things run in order
        -- ERROR: Extra Data is an object or instance
        data = data or {}
        if typeof(data) ~= "table" then
            prettyError(operation, state, ("Invalid ExtraData. A vanilla table was expected, but got a %q"):format(typeof(data)))
        end

        -- Update cached extraData
        self.lastData = data

        -- Get current state
        local oldState = self:GetState()
        local oldStackSize = #self.stateStack

        -- Asset state is valid
        if operation ~= OPERATION_POP and not self:IsStateValid(state) then
            prettyError(operation, state, ("The given state is not valid: " .. tostring(state)))
        end

        -- ERROR: State is already present in the stack.
        if operation == OPERATION_PUSH or operation == OPERATION_REPLACE then
            for i = #self.stateStack - 1, 1, -1 do
                local stackedState = self.stateStack[i]
                if stackedState == state then
                    prettyError(operation, state, "State is already present in the stack. Try :PopTo instead.")
                end
            end
        end

        -- ERROR: State is empty, or will become empty
        if operation == OPERATION_POP then
            if #self.stateStack < 2 then
                prettyError(operation, state, "Stack is empty, or would become empty after the operation. Try :Replace instead.")
            end
        end

        -- Calculate index to pop to
        local popToIndex = -1
        if operation == OPERATION_POP_TO or operation == OPERATION_POP_TO_AND_PUSH then
            for i, stackedState in pairs(self.stateStack) do
                if stackedState == state then
                    popToIndex = i
                    break
                end
            end
        end

        -- ERROR: State is not present in the stack (PopTo)
        if operation == OPERATION_POP_TO then
            if popToIndex < 1 then
                prettyError(operation, state, "State is not present in the stack. Try :PopToAndPush instead.")
            end
        end

        -- SILENT ERROR: State is not present in the stack (Remove)
        if operation == OPERATION_REMOVE then
            if not self:HasState(state) then
                return
            end
        end

        -- ERROR: Cannot PopTo top state
        if operation == OPERATION_POP_TO or operation == OPERATION_POP_TO_AND_PUSH then
            if popToIndex >= #self.stateStack then
                prettyError(operation, state, "State is already at the top.")
            end
        end

        -- Print traceback
        if self.isDebugPrintingEnabled and SHOW_TRACEBACK_IN_DEBUG then
            prettyDebug("Traceback:", debug.traceback())
        end

        -- Print state changes (before)
        if self.isDebugPrintingEnabled then
            prettyDebug("Stack before operation:", table.concat(self.stateStack, " -> "))
            prettyDebug(("-> Operation: %s, State: %s"):format(operation, state or "nil"))
        end

        -- Change state
        self:_ChangeState(operation, state, popToIndex)

        -- Print state changes (after)
        if self.isDebugPrintingEnabled then
            prettyDebug("-> Stack after operation:", table.concat(self.stateStack, " -> "))
        end

        -- Get current state
        local currentState = self:GetState()
        local currentStackSize = #self.stateStack
        local hasStateChanged = oldState ~= currentState
        local _isOldStateDiscarded = hasStateChanged and oldStackSize >= currentStackSize

        -- Reset total state time
        if hasStateChanged then
            self.stateTotalTime = 0
        end

        -- Fire global callback
        if self.eventGlobal then
            self.eventGlobal:Fire(oldState, currentState, data)
        end
    end)
end

--[[
    Pushes a state onto the stack. In other words, puts a state at the top of this state machine.
]]
function StateMachine:Push(state: string, data: table?)
    self:_RunOperation(OPERATION_PUSH, state, data)
end

--[[
    Replaces a state from the top of the stack.
]]
function StateMachine:Replace(state: string, data: table?)
    self:_RunOperation(OPERATION_REPLACE, state, data)
end

--[[
    Pops a state from the stack. In other words, removes the state at the top of this state machine.
]]
function StateMachine:Pop(data: table?)
    self:_RunOperation(OPERATION_POP, nil, data)
end

--[[
    Pops states from the stack until the given state is found.
]]
function StateMachine:PopTo(state: string, data: table?)
    self:_RunOperation(OPERATION_POP_TO, state, data)
end

--[[
    Similar to PopTo, but the state is pushed in case it's not present in the stack.
]]
function StateMachine:PopToAndPush(state: string, data: table?)
    self:_RunOperation(OPERATION_POP_TO_AND_PUSH, state, data)
end

--[[
    Pops all states and pushes / replaces the last one.
]]
function StateMachine:ClearAndPush(state: string, data: table?)
    self:_RunOperation(OPERATION_CLEAR_AND_PUSH, state, data)
end

--[[
    Removes a state from the stack, even if it's not on top.
]]
function StateMachine:Remove(state: string)
    self:_RunOperation(OPERATION_REMOVE, state, false)
end

--[[
    Ensures the given state is registered to this machine.
]]
function StateMachine:IsStateValid(state: string): boolean
    -- Invalid type
    if not state or type(state) ~= "string" then
        return false
    end

    -- Check registered states
    for _, registeredState in pairs(self.registeredStates) do
        if registeredState == state then
            return true
        end
    end

    -- State is not registered
    return false
end

--[[
    The current state at the top of the stack
]]
function StateMachine:GetState(): string
    return self.stateStack[#self.stateStack]
end

--[[
    Pops the state machine if the passed state is on the top of the stack
]]
function StateMachine:PopIfStateOnTop(state: string, data: table?)
    if self:GetState() == state then
        self:Pop(data)
    end
end

--[[
    The data passed on the last state changed
]]
function StateMachine:GetData(): table
    return self.lastData
end

--[[
    Returns whether this StateMachine has the given state in the stack.
]]
function StateMachine:HasState(state: string): boolean
    return table.find(self.stateStack, state) and true or false
end

--[[
    Will :Push() if the state is not in the stack at all
]]
function StateMachine:PushIfMissing(state: string, data: table?)
    if not self:HasState(state) then
        self:Push(state, data)
    end
end

--[[
    Counts how many states are in the stack.
]]
function StateMachine:GetStateCount(): number
    return #self.stateStack
end

--[[
    Enables/Disables the debug printing mode where state changes are printed to the output view.
]]
function StateMachine:SetDebugPrintingEnabled(isEnabled: boolean)
    self.isDebugPrintingEnabled = isEnabled

    if isEnabled then
        prettyDebug("Enabled Debug Printing.", "Started on State:", self:GetState())
    else
        prettyDebug("Disabled Debug Printing")
    end
end

--[[
    Adds a callback function that's called every time this machine changes its state.
]]
function StateMachine:RegisterGlobalCallback(callback: (fromState: string, toState: string, data: table?) -> ()): RBXScriptConnection
    return self.eventGlobal:Connect(callback)
end

--[[
    Adds enter and exit callback functions for when a specific state is enabled or disabled.
	If callNow=true, will call enterCallback if we are in that state at time of calling this method
]]
function StateMachine:RegisterStateCallbacks(
    state: string,
    enterCallback: ((data: table?) -> ())?,
    exitCallback: ((data: table?) -> ())?,
    callNow: boolean | nil,
    callNowData: table | nil
): RBXScriptConnection
    if callNow and self:GetState() == state then
        enterCallback(callNowData)
    end

    return self:RegisterGlobalCallback(function(fromState, toState, data)
        if fromState == state and exitCallback then
            exitCallback(data)
        end
        if toState == state and enterCallback then
            enterCallback(data)
        end
    end)
end

--[[
    Disposes all internal resources of this machine.
]]
function StateMachine:Destroy()
    self.eventGlobal:Destroy()
end

return StateMachine
