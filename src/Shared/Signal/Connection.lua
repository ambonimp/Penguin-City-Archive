local Connection = {}

type Handler = () -> ()

function Connection.new(handler: Handler, parent: { [number]: any })
	local id = #parent + 1

	local connection = {
		Handler = handler,
	}

	function connection:Disconnect()
		parent[id] = nil
	end

	parent[id] = connection
	return connection
end

export type Connection = typeof(Connection.new(function() end, {}))
export type ConnectionHandler = Handler

return Connection
