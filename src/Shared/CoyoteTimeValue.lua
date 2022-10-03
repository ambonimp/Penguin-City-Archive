--[[
    This is a class that mirrors "Coyote Time" behaviour.

    Example:
     - When a user clicks the screen, we run some logic based off what part the users mouse is hovering over (raycasting each frame)
     - The part the user is hovering over may get updated by the click (e.g., mobile Touch). We may want to wait a few frames
        to ensure the raycast can hit anything important, before running logic off the raycast from the click.
]]
local CoyoteTimeValue = {}

local RunService = game:GetService("RunService")

local function validatorNonNil(value: any)
    return value ~= nil
end

function CoyoteTimeValue.new(startValue: any?)
    local coyoteTimeValue = {}

    -------------------------------------------------------------------------------
    -- Private Members
    -------------------------------------------------------------------------------

    local value = startValue
    local connection: RBXScriptConnection?
    local connectionCounter = 0

    -------------------------------------------------------------------------------
    -- Private Methods
    -------------------------------------------------------------------------------

    local function disconnect()
        if connection and connection.Connected then
            connection:Disconnect()
        end
        connection = nil
    end

    -------------------------------------------------------------------------------
    -- Public Methods
    -------------------------------------------------------------------------------

    function coyoteTimeValue:SetValue(newValue: any)
        value = newValue
    end

    function coyoteTimeValue:GetValue()
        return value
    end

    --[[
        Runs some logic for `timeframe`
         - If our internal value when passed through `validator` returns `true`, we will run `callback(value)` *once*
         - This call returns a function that when called, with stop this logic running before `timeframe` need expire
    ]]
    function coyoteTimeValue:CallbackWithValidator(validator: (value: any) -> boolean, callback: (value: any) -> nil, timeframe: number)
        -- Disconnect old connection
        disconnect()

        local disconnectAtTick = tick() + timeframe
        connection = RunService.Heartbeat:Connect(function()
            if validator(value) then
                connection:Disconnect()
                callback(value)
                return
            end

            if tick() >= disconnectAtTick then
                connection:Disconnect()
            end
        end)

        connectionCounter += 1
        local thisConnectionCounter = connectionCounter

        -- Returns a function that will disconnect this specific call only
        return function()
            if connectionCounter == thisConnectionCounter then
                disconnect()
            end
        end
    end

    -- Ditto to CallbackWithValidator, but the validator just requires the value to be non-nil
    function coyoteTimeValue:CallbackNonNil(callback: (value: any) -> nil, timeframe: number)
        return self:CallbackWithValidator(validatorNonNil, callback, timeframe)
    end

    return coyoteTimeValue
end

return CoyoteTimeValue
