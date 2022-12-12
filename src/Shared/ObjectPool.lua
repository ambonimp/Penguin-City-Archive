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
    local objects: { [ObjectGroup]: true }? = {}
    local pool: { ObjectGroup }?

    -------------------------------------------------------------------------------
    -- PUBLIC MEMBERS
    -------------------------------------------------------------------------------
    objectPool.Cleared = Signal.new()

    -------------------------------------------------------------------------------
    -- PRIVATE METHODS
    -------------------------------------------------------------------------------
    local function createObject()
        local objectGroup = if typeof(template) == "Instance" then { template:Clone() } else template() :: ObjectGroup
        objects[objectGroup] = true -- Indexing is faster
        table.insert(pool, objectGroup)
    end

    -------------------------------------------------------------------------------
    -- PUBLIC METHODS
    -------------------------------------------------------------------------------
    function objectPool:GetObject(): ObjectGroup
        local objectGroup = pool[#objects]

        -- ERROR: Empty pool
        if objectGroup == nil then
            error("ObjectGroup pool is empty, check size")
        end

        return objectGroup
    end

    function objectPool:ReleaseObject(objectGroup: ObjectGroup)
        if objects[objectGroup] then
            error("Attempting to release an objectGroup that doesn't belong to the pool")
        end

        if table.find(pool, objectGroup) then
            return
        end

        onRelease(objectGroup)
        table.insert(pool, objects)
    end

    -- Release all objects
    function objectPool:Clear()
        for objectGroup in pairs(objects) do
            objectPool:ReleaseObject(objectGroup)
        end
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

        objectPool:ReleaseAll()

        if difference > 0 then
            for _ = 1, difference do
                createObject()
            end
        else
            difference = math.abs(difference)
            for objectGroup in pairs(objects) do
                if difference == 0 then
                    return
                end

                objects[objectGroup] = nil
                difference -= 1
            end
        end
    end

    function objectPool:Destroy()
        objectPool:ReleaseAll()

        for objectGroup in pairs(objects) do
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
