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

function TimeUtil.formatRelativeTime(seconds: number)
    local isNegative = seconds < 0
    seconds = math.abs(seconds)

    local function formatRelativeTime(a: number, longSuffix: string)
        a = math.floor(a) * (isNegative and -1 or 1)

        local plural = math.abs(a) > 1 and "s" or ""
        return ("%d %s%s"):format(a, longSuffix, plural)
    end

    if seconds < SECONDS_PER_MINUTE then
        local a = math.floor(seconds)
        return formatRelativeTime(a, "second")
    elseif seconds < SECONDS_PER_HOUR then
        local a = math.floor(seconds / SECONDS_PER_MINUTE)
        return formatRelativeTime(a, "minute")
    elseif seconds < SECONDS_PER_DAY then
        local a = math.floor(seconds / SECONDS_PER_HOUR)
        return formatRelativeTime(a, "hour")
    elseif seconds < SECONDS_PER_MONTH then
        local a = math.floor(seconds / SECONDS_PER_DAY)
        return formatRelativeTime(a, "day")
    elseif seconds < SECONDS_PER_YEAR then
        local a = math.floor(seconds / SECONDS_PER_MONTH)
        return formatRelativeTime(a, "month")
    else
        local a = math.floor(seconds / SECONDS_PER_YEAR)
        return formatRelativeTime(a, "year")
    end
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
