--[[
    This file makes it nice and easy to run checks on all current and future descendants of an instance(s)
    ]]
local DescendantLooper = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Janitor = require(ReplicatedStorage.Packages.janitor)

local THROTTLE_EVERY = 5000 -- Throttle after this many items are iterated over in one call

local instanceCheckerCallbackPairs: { [Instance]: { [(descendant: Instance) -> boolean]: (descendant: Instance) -> nil } } = {}

--[[
    Returns the dictionary for checker/callback pairings.
    Also sets up descendant added for first-time calls for individual instances
]]
local function getInstanceCheckerCallbackPairs(instance: Instance)
    if not instanceCheckerCallbackPairs[instance] then
        instanceCheckerCallbackPairs[instance] = {}

        local count = 0
        instance.DescendantAdded:Connect(function(descendant)
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
        end)

        -- Cleanup cache
        instance.Destroying:Connect(function()
            instanceCheckerCallbackPairs[instance] = nil
        end)
    end

    return instanceCheckerCallbackPairs[instance]
end

--[[
    Adds a checker/callback pair for looping all passed instances
]]
function DescendantLooper.add(
    checker: (descendant: Instance) -> boolean,
    callback: (descendant: Instance) -> nil,
    instances: { Instance },
    ignoreAdded: boolean?
): () -> ({ Instance })
    ignoreAdded = ignoreAdded or false

    -- Cache checker/callback for new added descendants
    local count = 0
    for _, instance in pairs(instances) do
        local checkerCallbackPairs = getInstanceCheckerCallbackPairs(instance)

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

    if not ignoreAdded then
        return function()
            local remainingDescedants: { Instance } = {}

            for _, instance in pairs(instances) do
                local checkerCallbackPairs = getInstanceCheckerCallbackPairs(instance)
                if instanceCheckerCallbackPairs then
                    checkerCallbackPairs[checker] = nil

                    for _, descendant in pairs(instance:GetDescendants()) do
                        table.insert(remainingDescedants, descendant)
                    end
                end
            end

            return remainingDescedants
        end
    end
end

--[[
    Adds a checker/callback pair for looping game.Workspace
]]
function DescendantLooper.workspace(
    checker: (descendant: Instance) -> boolean,
    callback: (descendant: Instance) -> nil,
    ignoreAdded: boolean?
)
    DescendantLooper.add(checker, callback, { game.Workspace }, ignoreAdded)
end

return DescendantLooper
