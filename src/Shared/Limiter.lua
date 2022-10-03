local Limiter = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

-- Constants
local MAX_TIME_FRAME = 300
local CONTEXT_ANY = "CONTEXT_ANY"

-- Types
type Indecision = {
    Timeframe: number,
    Hash: any,
}

-- Members
local debounces: { [any]: { [any]: number | nil } | nil } = {}
local indecisions: { [string]: Indecision } = {}

-- Returns true if free
function Limiter.debounce(scope, key, timeframe)
    -- TRUE: Negligible timeframe
    if timeframe <= 0 then
        return true
    end
    timeframe = math.clamp(timeframe, 0, MAX_TIME_FRAME)

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

--[[
	This helps us stop spamming contradicting logic in quick succession (e.g., client is constantly toggle a button on/off),
	so we only run logic periodically when there is a certain level of certainty (defined by `timeframe`)
]]
function Limiter.indecisive(key: string, timeframe: number, callback: (any) -> (any))
    -- Clean Params
    if not (timeframe > 0 and timeframe <= MAX_TIME_FRAME) then
        warn(("[Limiter] Timeframe %.2f is out of bounds. Clamping."):format(timeframe))
    end
    timeframe = math.clamp(timeframe, 0, MAX_TIME_FRAME)

    -- Create/Update Indecision
    local indecision = indecisions[key]
    local hash = tick()
    if not indecision then
        indecision = {}
        indecisions[key] = indecision
    end
    indecision.Timeframe = timeframe
    indecision.Hash = hash

    -- Run callback after timeframe
    task.delay(timeframe, function()
        -- RETURN: Indecision is gone??
        local currentIndecision = indecisions[key]
        if not currentIndecision then
            return
        end

        -- RETURN: Received a new decision since
        if currentIndecision.Hash ~= hash then
            return
        end

        -- Is a solid decision; run + clear cache
        indecisions[key] = nil
        callback()
    end)
end

return Limiter
