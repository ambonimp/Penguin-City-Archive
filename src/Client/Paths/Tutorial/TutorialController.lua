local TutorialController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local TutorialConstants = require(Paths.Shared.Tutorial.TutorialConstants)
local DataController = require(Paths.Client.DataController)
local TutorialUtil = require(Paths.Shared.Tutorial.TutorialUtil)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local CharacterItemUtil = require(Paths.Shared.CharacterItems.CharacterItemUtil)
local Signal = require(Paths.Shared.Signal)
local StringUtil = require(Paths.Shared.Utils.StringUtil)

TutorialController.StartTask = Signal.new() -- { task: string } used to kickstart the next tutorial task

local locallyCompletedTasks: { [string]: true } = {}

-------------------------------------------------------------------------------
-- Private Methods
-------------------------------------------------------------------------------

local function assertTask(task: string)
    if not TutorialConstants.Tasks[task] then
        error(("Bad task %q"):format(task))
    end
end

-- Returns true if started next task
local function startNextTask()
    for _, someTask in pairs(TutorialConstants.TaskOrder) do
        print(someTask, "completed", TutorialController.isTaskCompleted(someTask))
        if not TutorialController.isTaskCompleted(someTask) then
            TutorialController.StartTask:Fire(someTask)
            return true
        end
    end

    return false
end

-------------------------------------------------------------------------------
-- Logic / Runners
-------------------------------------------------------------------------------

function TutorialController.Start()
    -- Hook up TaskRunners
    do
        -- Get task runner callbacks
        local taskRunners: { [string]: () -> any } = {}
        for _, moduleScript in pairs(Paths.Client.Tutorial.TaskRunners:GetChildren()) do
            -- ERROR: Bad naming
            local taskName = StringUtil.chopStart(moduleScript.Name, "TutorialTask")
            if not taskName then
                error(("TutorialTaskRunner %s badly named; must be 'TutorialTask<TASK_NAME>'"):format(moduleScript:GetFullName()))
            end
            if not TutorialConstants.Tasks[taskName] then
                error(("TutorialTaskRunner %s badly named; no task %q"):format(moduleScript:GetFullName(), taskName))
            end

            -- ERROR: Must return a function
            local taskCallback = require(moduleScript)
            if not typeof(taskCallback) == "function" then
                error(("TutorialTaskRunner %s does not return a function1"):format(moduleScript:GetFullName()))
            end

            -- ERROR: Duplicate
            if taskRunners[taskName] then
                error(("Duplicate TutorialTaskRunner %q"):format(taskName))
            end

            taskRunners[taskName] = taskCallback
        end

        -- ERROR: Mismatch for tasks and taskrunners
        for _, task in pairs(TutorialConstants.Tasks) do
            if not taskRunners[task] then
                print(taskRunners)
                error(("Missing TaskRunner for task %q"):format(task))
            end
        end

        -- Invoke off of `StartTask`
        TutorialController.StartTask:Connect(function(task)
            -- ERROR: Missing taskrunner
            local taskCallback = taskRunners[task]
            if not taskCallback then
                error(("Bad task passed to StartTask Signal %q"):format(task))
            end

            -- Ensure Tutorial UI is here!
            if not UIController.getStateMachine():HasState(UIConstants.States.Tutorial) then
                UIController.getStateMachine():Push(UIConstants.States.Tutorial)
            end

            print("call task callback", task)
            taskCallback()
        end)
    end

    -- Kickstart Tutorial
    startNextTask()
end

-------------------------------------------------------------------------------
-- Setters / Getters
-------------------------------------------------------------------------------

-- Set a task as completely locally for immediate feedback to client for prime UX
function TutorialController.taskCompleted(task: string)
    warn("TASK COMPLETED", task, debug.traceback())
    assertTask(task)

    -- ERROR: Already completed
    if TutorialController.isTaskCompleted(task) then
        error(("Task %q already completed!"):format(task))
    end

    -- Update Cache
    locallyCompletedTasks[task] = true

    -- Inform Server
    Remotes.fireServer("TutorialTaskCompleted", task)

    local didStartNextTask = startNextTask()
    if not didStartNextTask then
        warn("todo completed all tasks")
    end
end

-- Queries local and server cache
function TutorialController.isTaskCompleted(task: string)
    assertTask(task)

    return (locallyCompletedTasks[task] or DataController.get(TutorialUtil.getTaskDataAddress(task))) and true or false
end

-------------------------------------------------------------------------------
-- Task Helpers
-------------------------------------------------------------------------------

-- Wrapper for TutorialScreen.prompt. Yields until prompt is skipped
function TutorialController.prompt(promptText: string)
    -- Circular Dependency
    local TutorialScreen = require(Paths.Client.UI.Screens.Tutorial.TutorialScreen)

    TutorialScreen.prompt(promptText)
end

function TutorialController.giveStarterPetEgg()
    -- Inform Server
    Remotes.fireServer("GiveStarterPetEgg")
end

--[[
    - Sets the task as completed
    - Applies the actual selected appearance to the players character, data etc..

    Indexes refer to TutorialConstants.StartingAppearance tables
]]
function TutorialController.setStartingAppearance(colorIndex: number, outfitIndex: number)
    -- Apply appearance locally
    do
        local character = Players.LocalPlayer.Character
        if character then
            CharacterItemUtil.applyAppearance(character, TutorialUtil.buildAppearanceFromColorAndOutfitIndexes(colorIndex, outfitIndex))
        end
    end

    -- Inform Server
    Remotes.fireServer("SetStartingAppearance", colorIndex, outfitIndex)
end

return TutorialController
