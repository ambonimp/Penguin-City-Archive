--[[
    Creates a bunch of instances from template instance(s) and stores and recycles them as needed.
]]

local ObjectPool = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Shared.Signal)
export type ObjectGroup = { Instance } | { [string]: Instance }

function ObjectPool.new(size: number, template: Instance | () -> (ObjectGroup), onRelease: (ObjectGroup) -> ())
    local objectPool = {}

    -------------------------------------------------------------------------------
    -- PRIVATE MEMBERS
    -------------------------------------------------------------------------------
    local objects: { ObjectGroup }? = {}
    local pool: { ObjectGroup }? = {}

    -------------------------------------------------------------------------------
    -- PUBLIC MEMBERS
    -------------------------------------------------------------------------------
    objectPool.Cleared = Signal.new()

    -------------------------------------------------------------------------------
    -- PRIVATE METHODS
    -------------------------------------------------------------------------------
    local function createObject()
        local objectGroup = if typeof(template) == "Instance" then { template:Clone() } else template() :: ObjectGroup
        table.insert(objects, objectGroup)
    end

    -------------------------------------------------------------------------------
    -- PUBLIC METHODS
    -------------------------------------------------------------------------------
    function objectPool:Get(): ObjectGroup
        -- ERROR: Empty pool
        if #objects == #pool then
            print(#objects, #pool)
            error("ObjectGroup pool is empty, check size")
        end

        for _, objectGroup in pairs(objects) do
            if not table.find(pool, objectGroup) then
                table.insert(pool, objectGroup)
                return objectGroup
            end
        end
    end

    function objectPool:Release(objectGroup: ObjectGroup)
        if not table.find(objects, objectGroup) then
            error("Attempting to release an objectGroup that doesn't belong to the pool")
        end

        local index = table.find(pool, objectGroup)
        if not index then
            return
        end

        onRelease(objectGroup)
        table.remove(pool, table.find(pool, index))
    end

    -- Release all objects
    function objectPool:Clear()
        for _, objectGroup in pairs(pool) do
            onRelease(objectGroup)
        end
        pool = {}
    end

    -- WARNING: Releases all objects
    function objectPool:Resize(newSize: number)
        local difference = newSize - size

        -- ERROR: Can't clear pool
        if newSize == 0 then
            error("Attempt to destroy pool, use Destroy")
        end

        -- RETURN: Size isn't changing
        if difference == 0 then
            return
        end

        objectPool:Clear()

        if difference > 0 then
            for _ = 1, difference do
                createObject()
            end
        else
            local currentSize = #objects
            for i = currentSize, currentSize + difference do
                table.remove(objects, i)
            end
        end
    end

    function objectPool:Destroy()
        objectPool:Clear()

        for _, objectGroup in pairs(objects) do
            for _, object in pairs(objectGroup) do
                object:Destroy()
            end
        end

        objects = nil
        pool = nil
    end

    -------------------------------------------------------------------------------
    -- LOGIC
    -------------------------------------------------------------------------------
    for _ = 1, size do
        createObject()
    end

    return objectPool
end

return ObjectPool
