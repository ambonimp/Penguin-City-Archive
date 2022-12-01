local TutorialService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Remotes = require(Paths.Shared.Remotes)
local TutorialConstants = require(Paths.Shared.Tutorial.TutorialConstants)
local DataService = require(Paths.Server.Data.DataService)
local TutorialUtil = require(Paths.Shared.Tutorial.TutorialUtil)

function TutorialService.completedTask(player: Player, task: string)
    -- RETURN: Already completed!
    if TutorialService.isTaskCompleted(player, task) then
        return
    end

    DataService.set(player, TutorialUtil.getTaskDataAddress(task), true, "TutorialTaskCompleted", {
        Task = task,
    })
end

function TutorialService.isTaskCompleted(player: Player, task: string)
    return DataService.get(player, TutorialUtil.getTaskDataAddress(task)) and true or false
end

-- Communication
Remotes.bindEvents({
    SetStartingAppearance = function(player: Player)
        --todo apply appearance
        --todo give products

        TutorialService.completedTask(player, TutorialConstants.Tasks.StartingAppearance)
    end,
})

return TutorialService
