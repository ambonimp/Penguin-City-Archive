local VersionFPSScreen = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)

local CACHE_TIMEFRAME = 2
local WRITE_FPS_EVERY = 0.25

local screenGui: ScreenGui = Paths.UI.VersionFPS
local fpsLabel: TextLabel = screenGui.Frame.FPS
local versionLabel: TextLabel = screenGui.Frame.Version
local versionValue: StringValue = ReplicatedStorage.Version

-- Version
versionLabel.Text = versionValue.Value

-- FPS
do
    -- Track the amount of frames
    local ticksCache = {}
    RunService.RenderStepped:Connect(function(_dt)
        -- Add this tick to cache
        local thisTick = tick()
        table.insert(ticksCache, 1, thisTick)

        -- Clear cache of bad ticks
        for i = #ticksCache, 1, -1 do
            local someTick = ticksCache[i]
            if (thisTick - someTick) > CACHE_TIMEFRAME then
                table.remove(ticksCache, i)
            else
                break
            end
        end
    end)

    -- Write the amount of frames
    task.spawn(function()
        while true do
            -- Write FPS
            local fps = #ticksCache / CACHE_TIMEFRAME
            fpsLabel.Text = ("%d FPS"):format(fps)

            task.wait(WRITE_FPS_EVERY)
        end
    end)
end

return VersionFPSScreen
