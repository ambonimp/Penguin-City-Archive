local ObjectPool = {}

type Object = { Instance } | { [string]: Instance }

function ObjectPool.new(size: number, template: Instance | () -> (Object), onRelease: (Object) -> ())
    local objectPool = {}

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------
    local objects: { [Object]: true }? = {}
    local pool: { Object }?
    -------------------------------------------------------------------------------
    -- PUBLIC MEMBERS
    -------------------------------------------------------------------------------
    function objectPool:GetObject(): Object
        local object = pool[#objects]
        -- ERROR: Empty pool
        if object == nil then
            error("Object pool is empty, check size")
        end

        return object
    end

    function objectPool:ReleaseObject(object: Object)
        if objects[object] then
            error("Attempting to release an object that doesn't belong to the pool")
        end

        if table.find(pool, object) then
            return
        end

        onRelease(object)
        table.insert(pool, objects)
    end

    function objectPool:ReleaseAll()
        for object in pairs(objects) do
            objectPool:ReleaseObject(object)
        end
    end

    function objectPool:Destroy()
        objectPool:ClearObjects()
        objects = nil
        pool = nil
    end

    -------------------------------------------------------------------------------
    -- LOGIC
    -------------------------------------------------------------------------------
    for _ = 1, size do
        local object = if typeof(template) == "Instance" then { template:Clone() } else template() :: Object
        objects[object] = true -- Indexing is faster
        table.insert(pool, object)
    end
end

return ObjectPool
