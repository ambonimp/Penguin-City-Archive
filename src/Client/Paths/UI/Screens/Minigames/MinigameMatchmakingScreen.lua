local MinigameQueueScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)

local screenGui: ScreenGui = Paths.UI.Minigames.Matchmaking
local queueFrame: Frame = screenGui.Queue
local queueStopwatch: TextLabel = queueFrame.Stopwatch

queueFrame.Exit.MouseButton1Down:Connect(function()
    ScreenUtil.outUp(queueFrame)
    Remotes.fireServer("MinigameQueueExited")
end)

Remotes.bindEvents({
    MinigameQueueJoined = function(minigame: string)
        queueFrame.Minigame.Text = minigame
        ScreenUtil.inDown(queueFrame)

        task.spawn(function()
            local et = 0
            while queueFrame.Visible do
                queueStopwatch.Text = et .. "s"
                et += 1
                task.wait(1)
            end
        end)
    end,

    MinigameQueueExited = function()
        if queueFrame.Visible then
            ScreenUtil.outUp(queueFrame)
        end
    end,
})

return MinigameQueueScreen
