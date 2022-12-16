local MinigameQueueScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local screenGui: ScreenGui = Paths.UI.Minigames.Matchmaking
local queueFrame: Frame = screenGui.Queue
local queueStopwatch: TextLabel = queueFrame.Stopwatch

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function MinigameQueueScreen.open(minigame: string, isMultiplayer: boolean)
    queueFrame.Exit.Visible = isMultiplayer
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
end

function MinigameQueueScreen.close()
    if queueFrame.Visible then
        ScreenUtil.outUp(queueFrame)
    end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
do
    queueFrame.Exit.MouseButton1Down:Connect(function()
        MinigameQueueScreen.close()
        Remotes.fireServer("MinigameQueueExited")
    end)
end

do
    Remotes.bindEvents({
        MinigameQueueJoined = function(minigameName: string)
            MinigameQueueScreen.open(minigameName, true)
        end,
    })
end

return MinigameQueueScreen
