local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestUtil = require(ReplicatedStorage.Shared.Utils.TestUtil)
local TutorialConstants = require(ReplicatedStorage.Shared.Tutorial.TutorialConstants)

return function()
    local issues: { string } = {}

    -- Tasks must be Enum
    TestUtil.enum(TutorialConstants.Tasks, issues)

    return issues
end
