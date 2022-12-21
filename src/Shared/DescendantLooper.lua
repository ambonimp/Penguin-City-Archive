--[[
    This file makes it nice and easy to run checks on all current and future descendants of an instance(s)
]]
local DescendantLooper = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.Shared.Maid)

local THROTTLE_EVERY = 5000 -- Throttle after this many items are iterated over in one call

--[[
    Adds a checker/callback pair for looping all passed instances.
    Returns a maid that can be destroyed to stop this operation - this is null if `ignoreAdded=true` though.
    !! A known issue is `callback` can be called twice when a new Instance is introduced into a scope being tracked by this method.
    !! as both `DescendantAdded` and `instance:GetDescendants()` will get the same instance
]]
function DescendantLooper.add(
    checker: (descendant: Instance) -> boolean,
    callback: (descendant: Instance) -> nil,
    instances: { Instance },
    ignoreAdded: boolean?
)
    local maid = Maid.new()
    local count = 0

    local function invokeCallback(descendant)
        -- Throttle
        if count % THROTTLE_EVERY == 0 then
            task.wait()
        end
        count = count + 1

        if checker(descendant) then
            task.spawn(callback, descendant)
        end
    end

    for _, instance in pairs(instances) do
        -- Run current instance loop
        for _, descendant in pairs(instance:GetDescendants()) do
            invokeCallback(descendant)
        end

        if not ignoreAdded then
            maid:GiveTask(instance.DescendantAdded:Connect(invokeCallback))
        end
    end

    return maid
end

--[[
    Adds a checker/callback pair for looping game.Workspace
]]
function DescendantLooper.workspace(
    checker: (descendant: Instance) -> boolean,
    callback: (descendant: Instance) -> nil,
    ignoreAdded: boolean?
)
    return DescendantLooper.add(checker, callback, { game.Workspace }, ignoreAdded)
end

--[[
    Will search descendants of `instances`, return an array of instances that passed `checker` (`checker` returns true)
]]
function DescendantLooper.search(instances: { Instance }, checker: (instance: Instance) -> boolean)
    local winners: { Instance } = {}

    local count = 0
    for _, parent in pairs(instances) do
        for _, descendant in pairs(parent:GetDescendants()) do
            if checker(descendant) then
                -- Throttle
                if count % THROTTLE_EVERY == 0 then
                    task.wait()
                end
                count = count + 1

                table.insert(winners, descendant)
            end
        end
    end

    return winners
end

return DescendantLooper
