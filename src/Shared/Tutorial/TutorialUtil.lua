local TutorialUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TutorialConstants = require(ReplicatedStorage.Shared.Tutorial.TutorialConstants)

function TutorialUtil.getTaskDataAddress(task: string)
    -- ERROR: Bad task
    if not TutorialConstants.Tasks[task] then
        error(("Bad task %q"):format(task))
    end

    return ("Tutorial.%s"):format(task)
end

return TutorialUtil
