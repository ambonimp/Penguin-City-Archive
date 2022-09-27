local Limiter = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local debounces: { [any]: { [any]: number | nil } | nil } = {}

-- Returns true if free
function Limiter.debounce(scope, key, timeframe)
    -- TRUE: Negligible timeframe
    if timeframe <= 0 then
        return true
    end

    -- FALSE: Locked
    local lockedUntilTick = debounces[scope] and debounces[scope][key]
    local thisTick = tick()
    if lockedUntilTick and lockedUntilTick > thisTick then
        return false
    end

    -- Register debounce
    local newLockedUntilTick = thisTick + timeframe
    debounces[scope] = debounces[scope] or {}
    debounces[scope][key] = newLockedUntilTick

    -- Schedule cache cleanup
    task.delay(timeframe, function()
        local currentLockedUntilTick = debounces[scope] and debounces[scope][key]
        local hasNotChanged = currentLockedUntilTick == newLockedUntilTick
        if hasNotChanged then
            debounces[scope][key] = nil

            if TableUtil.isEmpty(debounces[scope]) then
                debounces[scope] = nil
            end
        end
    end)

    -- TRUE: Free
    return true
end

return Limiter
