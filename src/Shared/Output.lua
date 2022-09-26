--[[
    Utility class that handles logging in the system, with different levels.
]]
local Output = {}

--[[
    Pattern that extracts the script's name and the current line from a stacktrace.

    - [_%w]+ = Represents all alphanumeric characters, plus underscores. This captures the script's name.
    - %d+ = Represents all digits. This captures the line of code being executed.

    More information at https://www.lua.org/manual/5.3/manual.html#6.4.1
]]
local TRACEBACK_PATTERN = "([_%w]+:%d+)"

local TRACEBACK_SOURCE_LINE = 4

-- Returns the name of the source being executed and its line of code as well.
local function getSourceName()
    local tracebackLines = debug.traceback():split("\n")
    if tracebackLines and #tracebackLines >= TRACEBACK_SOURCE_LINE then
        local sourceLine = tracebackLines[TRACEBACK_SOURCE_LINE]
        if sourceLine then
            for trace in sourceLine:gmatch(TRACEBACK_PATTERN) do
                return trace
            end
        end
    end
    return "Unknown Source"
end

-- Concatenates a vararg into a string. All vararg values are parsed as string before being concatenated.
local function concatVararg(...: any)
    local array = { ... }
    for i, value in ipairs(array) do
        array[i] = tostring(value)
    end
    return table.concat(array, " ")
end

--[[
    Granular flow information useful when developing systems.
]]
function Output.trace(...: any)
    print("👀 [" .. getSourceName() .. " - Trace]", ...)
end

--[[
    Low-level information on the flow through the system, mostly for developers.
]]
function Output.debug(...: any)
    print("🔸 [" .. getSourceName() .. " - Debug]", ...)
end

--[[
    Low-level information on the flow through the system, mostly for developers.
    - Only outputs if `doOutput=true`
]]
function Output.doDebug(doOutput: boolean, ...: any)
    if doOutput then
        Output.debug(...)
    end
end

--[[
    Generic and useful information about system operation.
]]
function Output.info(...: any)
    print("🔹 [" .. getSourceName() .. " - Info]", ...)
end

--[[
    Warnings, poor usage of the API, or 'almost' errors.
]]
function Output.warn(...: any)
    local msg = concatVararg(...)
    warn("🚧 [" .. getSourceName() .. " - Warn] " .. msg)
end

--[[
    Severe runtime errors or unexpected conditions.
]]
function Output.error(...: any)
    local msg = concatVararg(...)
    error("❌️ [" .. getSourceName() .. " - Error] " .. msg, TRACEBACK_SOURCE_LINE)
end

return Output
