--[[
    This file makes it nice and easy to run checks on all current and future descendants of an instance(s)
]]
local DescendantLooper = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InstanceUtil = require(ReplicatedStorage.Shared.Utils.InstanceUtil)
local Maid = require(ReplicatedStorage.Packages.maid)

local THROTTLE_EVERY = 5000 -- Throttle after this many items are iterated over in one call

local instanceCheckerCallbackPairs: { [Instance]: { [(descendant: Instance) -> boolean]: (descendant: Instance) -> nil } } = {}

--[[
    Returns the dictionary for checker/callback pairings.
    Also sets up descendant added for first-time calls for individual instances
]]
local function getInstanceCheckerCallbackPairs(instance: Instance, maid: typeof(Maid.new()))
    if not instanceCheckerCallbackPairs[instance] then
        instanceCheckerCallbackPairs[instance] = {}
        maid:GiveTask(function()
            instanceCheckerCallbackPairs[instance] = nil
        end)

        local count = 0
        maid:GiveTask(instance.DescendantAdded:Connect(function(descendant)
            -- Throttle
            if count % THROTTLE_EVERY == 0 then
                task.wait()
            end
            count += 1

            for checker, callback in pairs(instanceCheckerCallbackPairs[instance]) do
                if checker(descendant) then
                    task.spawn(callback, descendant)
                end
            end
        end))

        -- Cleanup cache
        InstanceUtil.onDestroyed(instance, function()
            instanceCheckerCallbackPairs[instance] = nil
        end)
    end

    return instanceCheckerCallbackPairs[instance]
end

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
    ignoreAdded = ignoreAdded or false

    local maid = Maid.new()

    -- Cache checker/callback for new added descendants
    local count = 0
    for _, instance in pairs(instances) do
        local checkerCallbackPairs = getInstanceCheckerCallbackPairs(instance, maid)

        if not ignoreAdded then
            checkerCallbackPairs[checker] = callback
        end

        -- Run current instance loop
        for _, descendant in pairs(instance:GetDescendants()) do
            -- Throttle
            if count % THROTTLE_EVERY == 0 then
                task.wait()
            end
            count = count + 1

            if checker(descendant) then
                task.spawn(callback, descendant)
            end
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

return DescendantLooper
