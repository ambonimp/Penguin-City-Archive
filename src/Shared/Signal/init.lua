local Connection = require(script.Connection)

-- Signal
local Signal = {}
export type Connection = typeof(Connection.new(function() end, {}))
export type Signal = typeof(Signal.new())

function Signal.new()
    local signal = {}

    local connections: { Connection.Handler } = {}
    local yields: { thread } = {}

    local function resumeAllThreads()
        for _, yieldingThread in pairs(yields) do
            local success, err = coroutine.resume(yieldingThread)
            if not success then
                warn(err)
            end
        end
        yields = {}
    end

    --[[
		Invokes all connections handlers connected to the signal and unyields all threads waiting for the signal
	]]
    function signal:Fire(...)
        for _, connectionHandler in pairs(connections) do
            task.spawn(connectionHandler, ...) -- Use spawn rather than coroutine because debug trace is better
        end
        resumeAllThreads()
    end

    --[[
		Registers a callback to be invoked when the signal is fired
	]]
    function signal:Connect(handler: (...any) -> nil)
        return Connection.new(handler, connections)
    end

    --[[
        Same as :Connect, but will disconnect itself after the first time `handler` is ran
    ]]
    function signal:Once(handler: (...any) -> nil)
        local connection: Connection
        connection = Connection.new(function()
            connection:Disconnect()
            handler()
        end, connections)

        return connection
    end

    --[[
		Yields the thread until the signal fired
	]]
    function signal:Wait(): thread
        table.insert(yields, coroutine.running())
        return coroutine.yield()
    end

    --[[
		Disconnects all connections connected to the signal and unyields all threads waiting for the signal
	]]
    function signal:Destroy()
        connections = {}
        signal = {}
        resumeAllThreads()
    end

    return signal
end

return Signal
