local Log = require(script.Parent.Parent.Log)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

local sdk = nil

local TRACEBACK_LINE_OLD = "([%w% %p]+)%, line (%d+)% ?%-?% ?([%w% %p]*)\n"
local MAX_ERRORS_PER_SERVER = 25
local MAX_UNIQUE_ERRORS = 1
local ERROR_MEMORY_EXPIRY_TIME = (60 * 60) * 24

local FIRE_EVENTS_LOOP_INTERVAL = 60 * 10
local IS_STUDIO = game:GetService("RunService"):IsStudio()
local errorsSentLastMinute = 0

local MessagingService = game:GetService("MessagingService")
local MemoryStore = game:GetService("MemoryStoreService")

local cachedErrors = {}
local blacklistedErrors = {}

local MESSAGING_TOPIC = "SENTRY_STOP"
local MESSAGING_TOPIC_EVENT_LIMIT = "SENTRY_STOP_EVENT"

local MEMORY_STORE_SENTRY = "SENTRY"

local isSentryEnabled = true

MessagingService:SubscribeAsync(MESSAGING_TOPIC, function(payload)
    isSentryEnabled = false
end)

MessagingService:SubscribeAsync(MESSAGING_TOPIC_EVENT_LIMIT, function(payload)
    blacklistedErrors[payload.Data.errorKey] = true
end)

-- Gets the memory store
local mem = MemoryStore:GetSortedMap(MEMORY_STORE_SENTRY)

-- Get blacklisted events on server starts up
local success, errorsBlacklist = pcall(function()
    return mem:GetRangeAsync(Enum.SortDirection.Ascending, 200)
end)
if not success then
    repeat
        task.wait(0.1)
        success, errorsBlacklist = pcall(function()
            return mem:GetRangeAsync(Enum.SortDirection.Ascending, 200)
        end)
    until success
end

for index, errorOnMemory in errorsBlacklist do
    blacklistedErrors[errorOnMemory.key] = true
end

local function fireEventsToSentry()
    for errorKey, cachedError in cachedErrors do
        if cachedError.extra.occurrences >= MAX_UNIQUE_ERRORS then
            MessagingService:PublishAsync(MESSAGING_TOPIC_EVENT_LIMIT, {
                errorKey = errorKey,
            })
            mem:SetAsync(errorKey, "", ERROR_MEMORY_EXPIRY_TIME)
        end

        if errorsSentLastMinute >= MAX_ERRORS_PER_SERVER then
            isSentryEnabled = false
            MessagingService:PublishAsync(MESSAGING_TOPIC, {})
            break
        end

        -- Update error count
        errorsSentLastMinute += 1

        -- Fires the event to SENTRY
        sdk.captureEvent(cachedError)
    end

    cachedErrors = {}
end

-- Routine to fire the errors tracked
spawn(function()
    while true do
        wait(FIRE_EVENTS_LOOP_INTERVAL)
        fireEventsToSentry()
    end
end)

-- Fire remaining events when server is closed
game:BindToClose(function()
    fireEventsToSentry()

    wait(5)
end)

return function(sentrySdk)
    if not sdk then
        sdk = sentrySdk
    end

    local ScriptContext = game:GetService("ScriptContext")
    local base = script.Parent.Parent:GetFullName()

    ScriptContext.Error:Connect(function(message, trace, runningScript)
        if not isSentryEnabled then
            return
        end

        if errorsSentLastMinute >= MAX_ERRORS_PER_SERVER then
            return
        end

        if trace:find(base, 1, true) then
            Log.warn("SDK error: " .. message .. "\n" .. trace)
            return
        end
        -- local trimmedMessage = message:match("^[%w% %p]+%:%d+: (.-)$")
        local frames = {}
        for fileName, lineNo, functionName in trace:gmatch(TRACEBACK_LINE_OLD) do
            table.insert(frames, 1, {
                filename = fileName,
                ["function"] = functionName,
                raw_function = functionName,
                lineno = tonumber(lineNo),
            })
        end
        if #frames == 0 then
            return
        end

        -- Prepare the error payload
        local event = {
            exception = {
                type = runningScript.Name,
                value = message,
                stacktrace = {
                    frames = frames,
                },
            },
            tags = {
                version = game.PlaceVersion,
                codebaseVersion = GameConstants.Version,
                isStudio = IS_STUDIO,
            },
            extra = {
                PlayersOnline = #Players:GetChildren(),
                serverId = game.JobId,
                placeId = game.PlaceId,
                occurrences = 1,
            },
        }

        local errorKey = runningScript.Name .. message
        if cachedErrors[errorKey] then
            cachedErrors[errorKey].extra.occurrences += 1
            return
        end

        if blacklistedErrors[errorKey] then
            return
        end

        cachedErrors[errorKey] = event

        local errorCount = 0
        for _, _ in cachedErrors do
            errorCount += 1
        end

        if errorCount >= MAX_ERRORS_PER_SERVER then
            fireEventsToSentry()
        end
    end)
end
