local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")



local Loader = {}

local Paths = require(script.Parent)
local modules = Paths.Modules
local ui = Paths.UI
local Transitions = require(script.Parent.UI.SpecialEffects.Transitions)



local LENGTH = 8
local FULL = 1.1 -- Gradient has 0.1 ease thing

local player = Players.LocalPlayer
local char, hrp

local screen = ui.LoadingScreen
local gradient = screen.Logo.Colored.UIGradient

local skipBtn = screen.Skip

local skipConn

local tween
local playing = true
local queue = {}



local function close()
    repeat
        task.wait()
    until skipBtn.Visible -- Character has loaded flag

    playing = false

    Transitions.blink(function()
        hrp.Anchored = false
        screen:Destroy()
    end)

end

function Loader.register(name, module)
    table.insert(queue, {name, module})
end

function Loader.load()
    local count = #queue
    local loaded = 0

    char = player.Character or player.CharacterAdded:Wait()
    hrp = char:WaitForChild("HumanoidRootPart")

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

    for i, loading in ipairs(queue) do
        modules[loading[1]] = require(loading[2])
        loaded += 1

        if screen.Enabled then
            if tween then
                tween:Cancel()
            end

            local progress = (loaded / count) * FULL - 0.1
            local speed = ((progress - gradient.Offset.X) / FULL) * ((LENGTH/count)/(1/count)) -- Contant speed
            tween = TweenService:Create(gradient, TweenInfo.new(speed, Enum.EasingStyle.Linear), {Offset = Vector2.new(progress, 0)})

            tween.Completed:Connect(function()
                if i == count and playing then
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