local Connection = {}

export type Handler = (...any) -> ()

function Connection.new(handler: Handler, connections: { [number]: Handler })
    local id = #connections + 1

    local connection = {}
    function connection:Disconnect()
        connections[id] = nil
    end

    function connection:Destroy()
        connection:Disconnect()
    end

    connections[id] = handler
    return connection
end

return Connection
