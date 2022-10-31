local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RewardsConstants = require(ReplicatedStorage.Shared.Rewards.RewardsConstants)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

return function()
    local issues: { string } = {}

    -- DailyStreakRewards Coins OR Gift
    for i, reward in pairs(RewardsConstants.DailyStreak.Rewards) do
        local totalOptions = (reward.Coins and 1 or 0) + (reward.Gift and 1 or 0)
        if totalOptions ~= 1 then
            table.insert(issues, ("DailyStreak.Rewards.%s must have `Coins` OR `Gift` defined"):format(tostring(i)))
        end
    end

    return issues
end
