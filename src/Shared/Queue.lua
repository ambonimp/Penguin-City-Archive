--[[
    Utilities relating to "queue"-esque logic
]]
local Queue = {}

local yieldingQueues: { [any]: { number } } = {}

--[[
    Allows us to yields threads that we may not want to run at the same time - this can help us avoid race condition stuff.

    - Returns a function that must be invoked to stop the next call from yielding
]]
function Queue.yield(scope: any)
    -- Get Queue
    local queue = yieldingQueues[scope]
    if not queue then
        queue = {}
        yieldingQueues[scope] = queue
    end

    local key = (queue[#queue] or 0) + 1
    table.insert(queue, key)

    while queue[1] ~= key do
        task.wait()
    end

    return function()
        table.remove(queue, 1)

        if #queue == 0 then
            yieldingQueues[scope] = nil
        end
    end
end

function Queue.addTask(scope: any, taskCallback: () -> nil)
    task.spawn(function()
        local nextQueue = Queue.yield(scope)
        taskCallback()
        nextQueue()
    end)
end

return Queue
