local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RewardsConstants = require(ReplicatedStorage.Shared.Rewards.RewardsConstants)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

return function()
    local issues: { string } = {}

    -- DailyStreakRewards Coins OR Gift
    for i, reward in pairs(RewardsConstants.DailyStreak.Rewards) do
        if (reward.Coins and reward.Gift) or not (reward.Coins or reward.Gift) then
            table.insert(issues, ("DailyStreak.Rewards.%s must have `Coins` OR `Gift` defined"):format(tostring(i)))
        end
    end

    return issues
end
