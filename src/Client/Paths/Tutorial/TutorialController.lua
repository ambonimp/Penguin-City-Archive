--[[
    Welcome to the tutorial scope!

    TutorialConstants contains the names for all of the tasks, and the order in which they will be completed.

    Each task has a "task runner": a callback that is invoked that runs the logic for that task. That runner must return a `Promise`! See the existing tasks
    for their implementation, but this helps us to skip the tutorial at any stage during a task.
    Pass tasks to the `taskMaid` to cleanup stuff when a task is finished with.
]]
local TutorialController = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local TutorialConstants = require(Paths.Shared.Tutorial.TutorialConstants)
local DataController = require(Paths.Client.DataController)
local TutorialUtil = require(Paths.Shared.Tutorial.TutorialUtil)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local CharacterItemUtil = require(Paths.Shared.CharacterItems.CharacterItemUtil)
local Signal = require(Paths.Shared.Signal)
local StringUtil = require(Paths.Shared.Utils.StringUtil)
local Maid = require(Paths.Shared.Maid)
local Promise = require(Paths.Packages.promise)
local Loader = require(Paths.Client.Loader)
local InteractionController = require(Paths.Client.Interactions.InteractionController)
local ZoneController = require(Paths.Client.Zones.ZoneController)
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local CharacterConstants = require(Paths.Shared.Constants.CharacterConstants)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local Snackbar = require(Paths.Client.UI.Elements.Snackbar)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIActions = require(Paths.Client.UI.UIActions)

TutorialController.StartTask = Signal.new() -- { task: string } used to kickstart the next tutorial task
TutorialController.TutorialSkipped = Signal.new()

local locallyCompletedTasks: { [string]: true } = {}
local taskMaid = Maid.new()
local currentTaskPromise: typeof(Promise.new(function() end)) | nil

local tutorialBooth: Model = Workspace.Rooms.Town.TutorialBooth

local idleAnimation = InstanceUtil.tree("Animation", { AnimationId = CharacterConstants.Animations.Idle[1].Id })
local waveAnimation = InstanceUtil.tree("Animation", { AnimationId = CharacterConstants.Animations.Wave[1].Id })

-------------------------------------------------------------------------------
-- Private Methods
-------------------------------------------------------------------------------
local function assertTask(task: string)
    if not TutorialConstants.Tasks[task] then
        error(("Bad task %q"):format(task))
    end
end

local function areAllTasksCompleted()
    for _, someTask in pairs(TutorialConstants.TaskOrder) do
        if not TutorialController.isTaskCompleted(someTask) then
            return false
        end
    end

    return true
end

-- Returns true if started next task
local function startNextTask()
    for _, someTask in pairs(TutorialConstants.TaskOrder) do
        if not TutorialController.isTaskCompleted(someTask) then
            TutorialController.StartTask:Fire(someTask)
            return true
        end
    end

    return false
end

local function loadTourGuide()
    if ZoneController.getCurrentZone().ZoneType == ZoneConstants.ZoneType.Room.Town then
        local animator: Animator = tutorialBooth.NPC.AnimationController.Animator
        local idleTrack = animator:LoadAnimation(idleAnimation)
        local waveTrack = animator:LoadAnimation(waveAnimation)

        task.spawn(function()
            while ZoneController.getCurrentZone().ZoneType == ZoneConstants.ZoneType.Room.Town do
                waveTrack:Play(nil, 2)
                task.wait(10)
            end

            idleTrack:Play(nil, 1)
        end)
    end
end

-------------------------------------------------------------------------------
-- Logic / Runners
-------------------------------------------------------------------------------

function TutorialController.Start()
    -- Hook up TaskRunners
    do
        -- Get task runner callbacks
        local taskRunners: { [string]: (taskMaid: Maid.Maid) -> typeof(currentTaskPromise) } = {}
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

            -- Cleanup last task
            if currentTaskPromise then
                currentTaskPromise:cancel()
            end
            taskMaid:Cleanup()

            -- Start new task
            -- Chained Promises that can be cancelled at any time if the user skips the tutorial

            -- ERROR: Not a promise!
            local returnedPromise = taskCallback(taskMaid)
            if not Promise.is(returnedPromise) then
                error(("TaskRunner %q did not return a Promise!"):format(task))
            end

            currentTaskPromise = returnedPromise:andThen(function()
                taskMaid:Cleanup()
                TutorialController.taskCompleted(task, task == TutorialConstants.Tasks.StartingAppearance)
            end)
        end)
    end

    -- Kickstart Tutorial (when loaded)
    Loader.ClientLoaded:Connect(function()
        if not TutorialController.isTaskCompleted(TutorialConstants.Tasks.StartingAppearance) then
            TutorialController.StartTask:Fire(TutorialConstants.Tasks.StartingAppearance)
        end
    end)
end

function TutorialController.skipTutorial()
    -- Run all necessary custom task helpers
    -- Okay if these get run twice, as we have installed anti-cheat on the server
    do
        TutorialController.giveStarterPetEgg()
    end

    -- Complete all tasks
    for _, task in pairs(TutorialConstants.Tasks) do
        if not TutorialController.isTaskCompleted(task, true) then
            TutorialController.taskCompleted(task, true)
        end
    end

    -- Cleanup existing task
    if currentTaskPromise then
        currentTaskPromise:cancel()
    end
    taskMaid:Cleanup()

    -- Tutorial is finished!
    UIController.getStateMachine():Remove(UIConstants.States.Tutorial)

    TutorialController.TutorialSkipped:Fire()
end

-------------------------------------------------------------------------------
-- Setters / Getters
-------------------------------------------------------------------------------

-- Set a task as completely locally for immediate feedback to client for prime UX (and then informs server as well)
function TutorialController.taskCompleted(task: string, dontStartNextTask: boolean?)
    assertTask(task)

    -- ERROR: Already completed locally
    if TutorialController.isTaskCompleted(task, true) then
        error(("Task %q already completed!"):format(task))
    end

    -- Update Cache
    locallyCompletedTasks[task] = true

    -- Inform Server
    Remotes.fireServer("TutorialTaskCompleted", task)

    if not dontStartNextTask then
        local didStartNextTask = startNextTask()
        if not didStartNextTask then
            -- Tutorial is finished!
            UIController.getStateMachine():Remove(UIConstants.States.Tutorial)
        end
    end
end

-- Queries local cache (and server cache if `locally` ~= true)
function TutorialController.isTaskCompleted(task: string, locally: boolean?)
    assertTask(task)

    return (locallyCompletedTasks[task] or (not locally and DataController.get(TutorialUtil.getTaskDataAddress(task)))) and true or false
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

-- Wrapper for TutorialScreen.prompt. Yields until finished
function TutorialController.tweenPetEggIntoInventory()
    -- Circular Dependency
    local TutorialScreen = require(Paths.Client.UI.Screens.Tutorial.TutorialScreen)

    TutorialScreen.egg(TutorialConstants.StarterEgg.PetEggName)
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

-------------------------------------------------------------------------------
-- Tutorial Booth Logic
-------------------------------------------------------------------------------
loadTourGuide()
ZoneController.ZoneChanged:Connect(loadTourGuide)

InteractionController.registerInteraction("TutorialPrompt", function(_, prompt)
    if areAllTasksCompleted() then
        Snackbar.info("Tutorial has already been completed")
        prompt.Enabled = false
    else
        UIActions.prompt("Tutorial", "Would you like to play the tutorial? (Recommended)", nil, {
            Text = "No",
            Callback = function()
                prompt.Enabled = true
            end,
        }, {
            Text = "Yes!",
            Callback = function()
                startNextTask()
                prompt.Enabled = false

                local connection
                connection = UIController.getStateMachine():RegisterStateCallbacks(UIConstants.States.Tutorial, nil, function()
                    connection:Disconnect()
                    prompt.Enabled = true
                end)
            end,
        })
    end
end, "Play Tutorial")

return TutorialController
