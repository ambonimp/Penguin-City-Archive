local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TimeUtil = {}

local SECONDS_PER_MINUTE = 60
local SECONDS_PER_HOUR = 3600
local SECONDS_PER_DAY = 86400
local SECONDS_PER_WEEK = 604800
local SECONDS_PER_MONTH = 2629743 -- 30.44 days
local SECONDS_PER_YEAR = 31556926 -- 365.24 days
local TIME_EMOJIS = { "🕛", "🕐", "🕑", "🕒", "🕓", "🕔", "🕕", "🕖", "🕗", "🕘", "🕙", "🕚" }
local TIME_EMOJIS_LENGTH = #TIME_EMOJIS

local MONTH_STR_MAP = {
    Jan = 1,
    Feb = 2,
    Mar = 3,
    Apr = 4,
    May = 5,
    Jun = 6,
    Jul = 7,
    Aug = 8,
    Sep = 9,
    Oct = 10,
    Nov = 11,
    Dec = 12,
}

local googleTimeInited = false
local googleTimeOriginTime: number
local googleTimeResponseTime: number
local googleTimeResponseDelay: number

-------------------------------------------------------------------------------
-- Time Conversions
-------------------------------------------------------------------------------

function TimeUtil.minutesToSeconds(minutes: number)
    return minutes * SECONDS_PER_MINUTE
end

function TimeUtil.secondsToMinutes(seconds: number)
    return seconds / SECONDS_PER_MINUTE
end

function TimeUtil.hoursToSeconds(hours: number)
    return hours * SECONDS_PER_HOUR
end

function TimeUtil.secondsToHours(seconds: number)
    return seconds / SECONDS_PER_HOUR
end

function TimeUtil.daysToSeconds(days: number)
    return days * SECONDS_PER_DAY
end

function TimeUtil.secondsToDays(seconds: number)
    return seconds / SECONDS_PER_DAY
end

function TimeUtil.weeksToSeconds(weeks: number)
    return weeks * SECONDS_PER_WEEK
end

function TimeUtil.secondsToWeeks(seconds: number)
    return seconds / SECONDS_PER_WEEK
end

function TimeUtil.monthsToSeconds(months: number)
    return months * SECONDS_PER_MONTH
end

function TimeUtil.secondsToMonths(seconds: number)
    return seconds / SECONDS_PER_MONTH
end

function TimeUtil.yearsToSeconds(years: number)
    return years * SECONDS_PER_YEAR
end

function TimeUtil.secondsToYears(seconds: number)
    return seconds / SECONDS_PER_YEAR
end

-------------------------------------------------------------------------------
-- Formatting
-------------------------------------------------------------------------------

local function formatToTimeUnit(int: number)
    return string.format("%02i", int)
end

function TimeUtil.formatSecondsToHMS(seconds: number)
    local hours = math.floor(TimeUtil.secondsToHours(seconds))
    seconds -= TimeUtil.hoursToSeconds(hours)
    local minutes = math.floor(TimeUtil.secondsToMinutes(seconds))
    seconds = math.round(seconds - TimeUtil.minutesToSeconds(minutes))

    return ("%s:%s:%s"):format(formatToTimeUnit(hours), formatToTimeUnit(minutes), formatToTimeUnit(seconds))
end

local function formatRelativeTime(seconds: number)
    local sign = seconds < 0 and -1 or 1
    seconds = math.abs(seconds)

    local function timeToString(num: number, longSuffix: string)
        num = math.floor(num) * sign

        local plural = math.abs(num) > 1 and "s" or ""
        return ("%d %s%s"):format(num, longSuffix, plural)
    end

    if seconds < SECONDS_PER_MINUTE then
        local num = math.floor(seconds)
        return timeToString(num, "second"), 0
    elseif seconds < SECONDS_PER_HOUR then
        local num = math.floor(TimeUtil.secondsToMinutes(seconds))
        return timeToString(num, "minute"), (seconds - TimeUtil.minutesToSeconds(num)) * sign
    elseif seconds < SECONDS_PER_DAY then
        local num = math.floor(TimeUtil.secondsToHours(seconds))
        return timeToString(num, "hour"), (seconds - TimeUtil.hoursToSeconds(num)) * sign
    elseif seconds < SECONDS_PER_MONTH then
        local num = math.floor(TimeUtil.secondsToDays(seconds))
        return timeToString(num, "day"), (seconds - TimeUtil.daysToSeconds(num)) * sign
    elseif seconds < SECONDS_PER_YEAR then
        local num = math.floor(TimeUtil.secondsToMonths(seconds))
        return timeToString(num, "month"), (seconds - TimeUtil.monthsToSeconds(num)) * sign
    else
        local num = math.floor(TimeUtil.secondsToYears(seconds))
        return timeToString(num, "year"), (seconds - TimeUtil.yearsToSeconds(num)) * sign
    end
end

--[[
    Formats the given time in seconds as relative time, such as "1 Minute" or "6 Days".
    `length` defines how many "types" to show
    e.g., a length of `2` for `90` seconds would return "1 Minute 30 Seconds"

    Returns the leftover seconds as a second parameter.
    e.g., `formatRelativeTime(70) -> "1 Minute", 10`
]]
function TimeUtil.formatRelativeTime(seconds: number, length: number?)
    length = length or 1

    local output = ""
    for i = 1, (length or 1) do
        if math.abs(seconds) > 0 then
            local str, leftoverSeconds = formatRelativeTime(seconds)

            output = ("%s%s%s"):format(output, i == 1 and "" or ", ", str)
            seconds = leftoverSeconds
        end
    end

    return output, seconds
end

--[[
    Each 1 second increment of seconds will display the next clock emoji
]]
function TimeUtil.getClockEmoji(seconds: number, invertDirection: boolean?)
    invertDirection = invertDirection or false

    seconds = math.floor(seconds)
    local index = (seconds % TIME_EMOJIS_LENGTH) + 1
    if invertDirection then
        index = TIME_EMOJIS_LENGTH - (index - 1)
    end
    return TIME_EMOJIS[index]
end

---Get a numerical date (in seconds) from a date string
local function RFC2616DateStringToUnixTimestamp(dateStr: string)
    local day, monthStr, year, hour, min, sec = dateStr:match(".*, (.*) (.*) (.*) (.*):(.*):(.*) .*")
    local month = MONTH_STR_MAP[monthStr]
    local date = {
        day = day,
        month = month,
        year = year,
        hour = hour,
        min = min,
        sec = sec,
    }

    return os.time(date)
end

--[[
    HTTP Requests google to get the current time. This is *very* useful for ensuring a synced time accross all servers.
    https://devforum.roblox.com/t/syncing-the-time-on-all-servers/244933
]]
function TimeUtil.getGoogleTime()
    -- ERROR: Server only
    if not RunService:IsServer() then
        error("Server only")
    end

    ---Initial load
    local function init()
        local ok, err = pcall(function()
            local requestTime = tick()
            local response = HttpService:RequestAsync({ Url = "http://google.com" })
            local dateStr = response.Headers.date
            googleTimeOriginTime = RFC2616DateStringToUnixTimestamp(dateStr)
            googleTimeResponseTime = tick()
            -- Estimate the response delay due to latency to be half the rtt time
            googleTimeResponseDelay = (googleTimeResponseTime - requestTime) / 2
            googleTimeInited = true
        end)
        if not ok then
            warn(("Error requesting time from google.com (%s)"):format(err))
            googleTimeOriginTime = os.time()
            googleTimeResponseTime = tick()
            googleTimeResponseDelay = 0
        end
    end

    local function time()
        if not googleTimeInited then
            init()
        end

        return googleTimeOriginTime + tick() - googleTimeResponseTime - googleTimeResponseDelay
    end

    return time()
end

return TimeUtil
