-- Connection
local Connection = {}
Connection.__index = Connection

function Connection:Disconnect()
    for i, connection in ipairs(self._Self.Connections) do
        if connection == self then
            table.remove(self._Self.Connections, i)
        end
    end

    setmetatable(self, nil)
end

Connection.Destroy = Connection.Disconnect



-- Signal
local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({
        Connections = {};
        Yields = {};
    }, Signal)
end

function Signal:Fire(...)
    for _, connection in ipairs(self.Connections) do
        coroutine.wrap(connection.Handler)(...)
    end

    for _, v in ipairs(self.Yields) do
        local success, err = coroutine.resume(v, ...)
        if not success then
            warn(err)
        end
    end

    self.Yields = {}

end

function Signal:Connect(handler)
    local connection = setmetatable({
        Handler = handler;
        _Self = self;
    }, Connection)

    table.insert(self.Connections, connection)
    return connection
end


function Signal:Wait()
    table.insert(self.Yields, coroutine.running())
    return coroutine.yield()
end

function Signal:BindHandlers(handlers)
    self:Connect(function(key, ...)
        for k, handler in pairs(handlers) do
            if key == k then
                handler(...)
            end
        end
    end)
end

function Signal:Destroy()
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end

    for _, v in ipairs(self.Yields) do
        coroutine.resume(v)
    end

    setmetatable(self, nil)
end

return Signal