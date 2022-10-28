local RewardsUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local DataUtil = require(ReplicatedStorage.Shared.Utils.DataUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local RewardsConstants = require(ReplicatedStorage.Shared.Rewards.RewardsConstants)
local TimeUtil = require(ReplicatedStorage.Shared.Utils.TimeUtil)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)

export type DailyStreakEntry = {
    StreakNumber: number,
    Days: number,
    RenewAtServerTime: number,
    ExpiresAtServerTime: number,
}

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

function RewardsUtil.getBestDailyStreak(dailyStreakData: DataUtil.Data)
    return dailyStreakData.BestStreak
end

function RewardsUtil.getTimeUntilNextDailyStreakRenew(dailyStreakData: DataUtil.Data)
    local entry = dailyStreakData.Entries["1"] :: DailyStreakEntry
    if entry then
        return math.clamp(entry.RenewAtServerTime - Workspace:GetServerTimeNow(), 0, math.huge)
    end
    return 0
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
            if expiredTime > TimeUtil.daysToSeconds(RewardsConstants.DailyStreak.StoreMaxDays) then
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

        entry.RenewAtServerTime = now + TimeUtil.hoursToSeconds(RewardsConstants.DailyStreak.RenewAfterHours)
        entry.ExpiresAtServerTime = entry.RenewAtServerTime + TimeUtil.hoursToSeconds(RewardsConstants.DailyStreak.ExpireAfterHours)
    end

    return {
        Entries = TableUtil.mapKeys(arrayDailyStreakEntries, function(key)
            return tostring(key)
        end),
        Unclaimed = dailyStreakData.Unclaimed,
        BestStreak = math.max(dailyStreakData.BestStreak, entry.Days),
    }
end

-- Cheeky utlility to change the time this dailyStreakData can renew
function RewardsUtil.setDailyStreakRenewTime(dailyStreakData: DataUtil.Data, renewTime: number)
    local entry = dailyStreakData.Entries["1"] :: DailyStreakEntry
    if entry then
        entry.RenewAtServerTime = renewTime
    end
end

function RewardsUtil.getReward(day: number)
    local wrappedDay = MathUtil.wrapAround(day, #RewardsConstants.DailyStreak.Rewards)
    local rewardLevel = math.ceil(day / #RewardsConstants.DailyStreak.Rewards)

    local reward = RewardsConstants.DailyStreak.Rewards[wrappedDay]
    if reward.Gift then
        reward.Gift = rewardLevel == 1 and "Small" or rewardLevel == 2 and "Medium" or "Large" --TODO Implement gifts properly
    end

    return reward
end

function RewardsUtil.getDailyStreakDataAddress()
    return "Rewards.DailyStreak"
end

return RewardsUtil
