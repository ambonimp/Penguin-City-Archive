local RewardsConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

export type DailyStreakReward = {
    Coins: number | nil,
    Gift: string | nil,
    Icon: string | nil,
    Color: Color3,
}

local dailyStreakRewards: { DailyStreakReward } = {
    { Coins = 25, Icon = Images.Coins.Bundle1, Color = Color3.fromRGB(38, 164, 162) },
    { Coins = 100, Icon = Images.Coins.Bundle2, Color = Color3.fromRGB(38, 164, 162) },
    { Coins = 250, Icon = Images.Coins.Bundle3, Color = Color3.fromRGB(38, 164, 162) },
    { Coins = 500, Icon = Images.Coins.Bundle4, Color = Color3.fromRGB(172, 89, 193) },
    { Gift = "", Icon = Images.Icons.Gift, Color = Color3.fromRGB(222, 125, 37) },
}

RewardsConstants.DailyStreak = {
    StoreMaxDays = 5,
    RenewAfterHours = 24,
    ExpireAfterHours = 28,
    Rewards = dailyStreakRewards,
}

return RewardsConstants
