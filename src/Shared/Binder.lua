local Binder = {}

Binder.Store = {}

--[[
    Registers an instance that stuff can be binded to
]]
function Binder.addInstance(scope: Instance)
    if not Binder.Store[scope] then
        Binder.Store[scope] = Binder.Store[scope] or {}
    end

    return Binder.Store[scope]
end

--[[
    Unregisters an instance and cleans up it's instances
]]
function Binder.removeInstance(scope: Instance)
    local bindings = Binder.Store[scope]
    if bindings then
        Binder.Store[scope] = nil
    end
end

function Binder.bind(scope: Instance, key: string, value: any): any
    local store = Binder.addInstance(scope)
    store[key] = value

    return value
end

function Binder.getBinded(scope: Instance, key: string)
    local bindings = Binder.Store[scope]

    if bindings then
        return bindings[key]
    end
end

--[[
    Initialize a bind with value if it doesn't already exist
]]
function Binder.bindFirst(scope: Instance, key: string, value: any)
    local binded = Binder.getBinded(scope, key)
    if binded then
        return binded, false
    else
        return Binder.bind(scope, key, value), true
    end
end

--[[
    Invokes a binded value's method
    Useful for overiding things like cancelling a tween that's been binded
]]
function Binder.invokeBindedMethod(scope: Instance, key: string, invoking: string)
    local binded = Binder.getBinded(scope, key)
    if binded then
        binded[invoking](binded)
    end
end

--[[
    Unbinds a binded value when a certain event is fired
    Usefull for state things when it comes to things like tweens
]]
function Binder.unbindOnBindedEvent(scope: Instance, key: string, event: string)
    local binded = assert(Binder.getBinded(scope, key))

    if binded[event] then
        local connection
        connection = binded[event]:Connect(function()
            connection:Disconnect()
            Binder.bind(scope, key, nil)
        end)
    end
end

return Binder
