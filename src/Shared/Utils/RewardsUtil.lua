local RewardsUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local DataUtil = require(ReplicatedStorage.Shared.Utils.DataUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

export type DailyStreakEntry = {
    StreakNumber: number,
    Days: number,
    RenewAtServerTime: number,
    ExpiresAtServerTime: number,
}

local STORE_DAILY_STREAK_MAX_DAYS = 5
local RENEW_DAILY_STREAK_AFTER_HOURS = 24
local EXPIRE_DAILY_STREAK_AFTER_HOURS = 28
local SECONDS_IN_AN_HOUR = 60 * 60
local SECONDS_IN_A_DAY = SECONDS_IN_AN_HOUR * 24

function RewardsUtil.getDailyStreakNumber(dailyStreakData: DataUtil.Data)
    local entry = dailyStreakData.Entries["1"] :: DailyStreakEntry
    if entry then
        return entry.StreakNumber
    end
    return nil
end

function RewardsUtil.getDailyStreakDays(dailyStreakData: DataUtil.Data)
    local entry = dailyStreakData.Entries["1"] :: DailyStreakEntry
    if entry then
        return entry.Days
    end
    return nil
end

--[[
    dailyStreakData = {
        Entries = {},
        Unclaimed = {},
    }
]]
function RewardsUtil.getUpdatedDailyStreak(dailyStreakData: DataUtil.Data)
    -- Convert to array for easier manipulation
    local arrayDailyStreakEntries: { DailyStreakEntry } = TableUtil.mapKeys(TableUtil.deepClone(dailyStreakData.Entries), function(key)
        return tonumber(key)
    end)
    local now = Workspace:GetServerTimeNow()

    -- Cull old entries
    for i = #arrayDailyStreakEntries, 1, -1 do
        local entry = arrayDailyStreakEntries[i]
        local expiredTime = now - entry.ExpiresAtServerTime
        local hasExpired = expiredTime > 0

        if hasExpired then
            -- Very old; remove
            if expiredTime > SECONDS_IN_A_DAY * STORE_DAILY_STREAK_MAX_DAYS then
                table.remove(arrayDailyStreakEntries, i)
            end
        end
    end

    -- Ensure good entry is at the top
    local entry = arrayDailyStreakEntries[1]
    local streakNumber = entry and entry.StreakNumber or 0
    if not entry or (entry.ExpiresAtServerTime < now) then
        entry = {
            StreakNumber = streakNumber + 1,
            Days = 0,
            RenewAtServerTime = 0,
            ExpiresAtServerTime = 0,
        }
        table.insert(arrayDailyStreakEntries, 1, entry)
    end

    -- Try renew
    if entry.RenewAtServerTime < now then
        entry.Days += 1
        dailyStreakData.Unclaimed[tostring(entry.Days)] = true

        entry.RenewAtServerTime = now + RENEW_DAILY_STREAK_AFTER_HOURS * SECONDS_IN_AN_HOUR
        entry.ExpiresAtServerTime = entry.RenewAtServerTime + EXPIRE_DAILY_STREAK_AFTER_HOURS * SECONDS_IN_AN_HOUR
    end

    return {
        Entries = TableUtil.mapKeys(arrayDailyStreakEntries, function(key)
            return tostring(key)
        end),
        Unclaimed = dailyStreakData.Unclaimed,
    }
end

-- Cheeky utlility to change the time this dailyStreakData can renew
function RewardsUtil.setDailyStreakRenewTime(dailyStreakData: DataUtil.Data, renewTime: number)
    local entry = dailyStreakData.Entries["1"] :: DailyStreakEntry
    if entry then
        entry.RenewAtServerTime = renewTime
    end
end

function RewardsUtil.getDailyStreakDataAddress()
    return "Rewards.DailyStreak"
end

return RewardsUtil
