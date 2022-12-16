local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestUtil = require(ReplicatedStorage.Shared.Utils.TestUtil)
local SportsGamesConstants = require(ReplicatedStorage.Shared.SportsGames.SportsGamesConstants)

return function()
    local issues: { string } = {}

    -- SportsEquipmentType Enum-like
    TestUtil.enum(SportsGamesConstants.SportsEquipmentType, issues)

    -- Verify types in PushEquipmentForceByType
    for sportsEquipmentType, _ in pairs(SportsGamesConstants.PushEquipmentForceByType) do
        if not SportsGamesConstants.SportsEquipmentType[sportsEquipmentType] then
            table.insert(issues, (("Bad SportsEuqipmentType SportsGamesConstants.PushEquipmentForceByType.%s"):format(sportsEquipmentType)))
        end
    end

    return issues
end
