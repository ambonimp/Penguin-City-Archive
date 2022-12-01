local Loader = {}

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TransitionFX = require(Paths.Client.UI.Screens.SpecialEffects.Transitions)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)

type Task = {
    Scope: string,
    Name: string,
    Task: () -> nil,
}

local LENGTH = 8
local FULL = 1.1 -- Gradient has 0.1 ease thing
local VERIFY_PLAYER_GUI_EVERY = 1

local localPlayer = Players.LocalPlayer
local character: Model, humanoidRootPart: Part
local screen: ScreenGui = Paths.UI:WaitForChild("LoadingScreen")
local gradient: UIGradient = screen.Logo.Colored.UIGradient
local skipBtn: ImageButton = screen.Skip
local skipConn: RBXScriptConnection?
local tween: Tween?
local playing = true
local taskQueue: { Task } = {}
local hasStartedLoading = false
local uiStateMachine = UIController.getStateMachine()

local function close()
    repeat
        task.wait()
    until skipBtn.Visible -- Character has loaded flag

    playing = false

    TransitionFX.blink(function()
        uiStateMachine:PopIfStateOnTop(UIConstants.States.Loading)

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

-- Will Yield until all ScreenGui in StarterGui are present in PlayerGui, with all of their descendants
function Loader.yieldPlayerGui()
    -- Get all ScreenGui + Descendant Counts in StarterGui
    local checklist: { [string]: number } = {}
    for _, screenGui: ScreenGui in pairs(StarterGui:GetDescendants()) do
        if screenGui:IsA("ScreenGui") then
            local name = screenGui.Name
            local totalDescendants = #screenGui:GetDescendants()

            -- ERROR: Duplicate Name!
            if checklist[name] then
                error(("Duplicate ScreenGui name %q - not allowed!"):format(name))
            end

            checklist[name] = totalDescendants
        end
    end

    local function verify()
        -- Grab all ScreenGuis in PlayerGui
        local screenGuis: { ScreenGui } = {}
        for _, descendant in pairs(Paths.UI:GetDescendants()) do
            if descendant:IsA("ScreenGui") then
                table.insert(screenGuis, descendant)
            end
        end

        -- Compare
        for screenGuiName, totalDescendants in pairs(checklist) do
            -- Get matching ScreenGui
            local screenGui: ScreenGui
            for _, someScreenGui in pairs(screenGuis) do
                if someScreenGui.Name == screenGuiName then
                    screenGui = someScreenGui
                    break
                end
            end

            -- FALSE: Does not exist
            if not screenGui then
                warn(("Still Loading PlayerGui (Couldn't find %q)"):format(screenGuiName))
                return false
            end

            -- FALSE: Not enough descendants
            local currentDescendants = #screenGui:GetDescendants()
            if currentDescendants < totalDescendants then
                warn(
                    ("Still Loading PlayerGui (%q needs %d descendants, has %d)"):format(
                        screenGuiName,
                        totalDescendants,
                        currentDescendants
                    )
                )
                return false
            end
        end

        -- Passed
        print("PlayerGui Loaded")
        return true
    end

    while verify() == false do
        task.wait(VERIFY_PLAYER_GUI_EVERY)
    end
end

function Loader.Start()
    -- ERROR: Already loading
    if hasStartedLoading then
        error(".load has already been called!")
    end
    hasStartedLoading = true
    uiStateMachine:Push(UIConstants.States.Loading)

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
