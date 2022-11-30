local RewardsStampAwarders = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local StampService = require(Paths.Server.Stamps.StampService)
local StampUtil = require(Paths.Shared.Stamps.StampUtil)
local RewardsService = require(Paths.Server.RewardsService)
local TimeUtil = require(Paths.Shared.Utils.TimeUtil)

-- events_playtime_payday, events_playtime_collect5
local eventsPlaytimePaydayStamp = StampUtil.getStampFromId("events_playtime_payday")
local eventsPlaytimeCollect5Stamp = StampUtil.getStampFromId("events_playtime_collect5")
RewardsService.GavePaycheck:Connect(function(player: Player, paycheckNumber: number)
    StampService.addStamp(player, eventsPlaytimePaydayStamp.Id)

    if paycheckNumber >= 5 then
        StampService.addStamp(player, eventsPlaytimeCollect5Stamp.Id)
    end
end)

-- events_playtime_streak1, events_playtime_day30
local eventsPlaytimeStreak1Stamp = StampUtil.getStampFromId("events_playtime_streak1")
local eventsPlaytimeDay30Stamp = StampUtil.getStampFromId("events_playtime_day30")
RewardsService.ClaimedDailyReward:Connect(function(player: Player, dayNum: number)
    if dayNum > 1 then
        StampService.addStamp(player, eventsPlaytimeStreak1Stamp.Id)
    end

    if dayNum >= 30 then
        StampService.addStamp(player, eventsPlaytimeDay30Stamp.Id)
    end
end)

-- events_playtime_mins20
local eventsPlaytimeMins20Stamp = StampUtil.getStampFromId("events_playtime_mins20")
Players.PlayerAdded:Connect(function(player)
    task.wait(TimeUtil.minutesToSeconds(20))
    local isStillOnline = player:IsDescendantOf(Players)
    if isStillOnline then
        StampService.addStamp(player, eventsPlaytimeMins20Stamp.Id)
    end
end)

return RewardsStampAwarders
