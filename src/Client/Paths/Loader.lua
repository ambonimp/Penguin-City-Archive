local Loader = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Ui = Paths.UI
local TransitionFX = require(Paths.Modules.UI.Screens.SpecialEffects.Transitions)

type Task = {
    Scope: string,
    Name: string,
    Task: () -> nil,
}

local LENGTH = 8
local FULL = 1.1 -- Gradient has 0.1 ease thing

local localPlayer = Players.LocalPlayer
local character: Model, humanoidRootPart: Part
local screen: ScreenGui = Ui:WaitForChild("LoadingScreen")
local gradient: UIGradient = screen.Logo.Colored.UIGradient
local skipBtn: ImageButton = screen.Skip
local skipConn: RBXScriptConnection?
local tween: Tween?
local playing = true
local taskQueue: { Task } = {}
local hasStartedLoading = false

local function close()
    repeat
        task.wait()
    until skipBtn.Visible -- Character has loaded flag

    playing = false

    TransitionFX.blink(function()
        humanoidRootPart.Anchored = false
        screen:Destroy()
    end)
end

function Loader.giveTask(scope: string, name: string, task: () -> nil)
    -- ERROR: Cannot give tasks once loading has started
    if hasStartedLoading then
        error("Cannot give task once loading has started - tasks should be given when a script is required.")
    end

    local newTask: Task = {
        Scope = scope,
        Name = name,
        Task = task,
    }
    table.insert(taskQueue, newTask)
end

function Loader.load()
    -- ERROR: Already loading
    if hasStartedLoading then
        error(".load has already been called!")
    end
    hasStartedLoading = true

    local totalTasks = #taskQueue
    local tasksCompleted = 0

    character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    -- Skipping
    task.spawn(function()
        task.wait(3)

        skipBtn.Visible = true
        skipConn = skipBtn.MouseButton1Down:Connect(function()
            skipConn:Disconnect()
            skipConn = nil

            if playing then
                close()
            end
        end)
    end)

    for i, newTask in ipairs(taskQueue) do
        newTask.Task()
        tasksCompleted += 1

        if screen.Enabled then
            if tween then
                tween:Cancel()
            end

            local progress = (tasksCompleted / totalTasks) * FULL - 0.1
            local speed = ((progress - gradient.Offset.X) / FULL) * ((LENGTH / totalTasks) / (1 / totalTasks)) -- Contant speed
            tween = TweenService:Create(gradient, TweenInfo.new(speed, Enum.EasingStyle.Linear), { Offset = Vector2.new(progress, 0) })

            tween.Completed:Connect(function()
                if i == totalTasks and playing then
                    task.wait(0.5)

                    playing = false
                    close()
                end

                tween = nil
            end)

            tween:Play()
        end
    end
end

return Loader
