local SledRaceScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local SharedMinigameScreen = require(Paths.Client.UI.Screens.Minigames.SharedMinigameScreen)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local player = Players.LocalPlayer

local screen: ScreenGui = Paths.UI.Minigames.SledRace
local instructionsFrame: Frame = screen.Instructions
local progressLine: Frame = screen.ProgressLine
local random = Random.new()

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------

function SledRaceScreen.openProgressLine(indicatorHeight: number): ({ [Player]: Frame }, number)
    local positions = {}

    for _, participant in pairs(MinigameController.getParticpants()) do
        local prioritize = participant == player

        local bar = Instance.new("Frame")
        bar.AnchorPoint = Vector2.new(1, 0)
        bar.BackgroundColor3 = Color3.fromRGB(random:NextInteger(0, 255), random:NextInteger(0, 255), random:NextInteger(0, 255))
        bar.Size = UDim2.new(if prioritize then 1.5 else 1, 0, 0, indicatorHeight)
        bar.Position = UDim2.new(1, 0, 1, -indicatorHeight)
        bar.ZIndex = if prioritize then 3 else 2
        bar.Parent = progressLine

        local icon = Instance.new("ImageLabel")
        icon.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        icon.BackgroundTransparency = 1
        icon.AnchorPoint = Vector2.new(1, 0.5)
        icon.Size = UDim2.fromOffset(80, 80)
        icon.Position = UDim2.new(0, 40, 0.5, 0)
        icon.ZIndex = if prioritize then 4 else 3
        icon.Parent = bar

        positions[participant] = bar
    end

    progressLine.Visible = true
    return positions, 1 - (indicatorHeight / progressLine.AbsoluteSize.Y)
end

function SledRaceScreen.closeProgressLine()
    progressLine.Visible = false

    for _, frame in pairs(progressLine:GetChildren()) do
        if frame:IsA("Frame") then
            frame:Destroy()
        end
    end
end

-------------------------------------------------------------------------------
-- Instructions
-------------------------------------------------------------------------------
do
    local exitButton = ExitButton.new()
    exitButton.Pressed:Connect(function()
        ScreenUtil.outDown(instructionsFrame)
        if not MinigameController.isMultiplayer() then
            SharedMinigameScreen.openStartMenu()
        end
    end)
    exitButton:Mount(instructionsFrame.Exit, true)
end

return SledRaceScreen
