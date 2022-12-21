local SledRaceScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local SharedMinigameScreen = require(Paths.Client.UI.Screens.Minigames.SharedMinigameScreen)
local PlayerIcon = require(Paths.Client.UI.Elements.PlayerIcon)

local PROGRESS_LINE_STROKE_COLOR = Color3.fromRGB(26, 26, 26)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local player = Players.LocalPlayer

local screen: ScreenGui = Paths.UI.Minigames.SledRace
local instructionsFrame: Frame = screen.Instructions

local progressLine: Frame = screen.ProgressLine
local progressIndicators: { [Player]: Frame }?

local coinCount: TextLabel = screen.Coins

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
function SledRaceScreen.openProgressLine(indicatorHeight: number): ({ [Player]: Frame }, number)
    progressIndicators = {}

    for _, participant in pairs(MinigameController.getParticpants()) do
        local prioritize = participant == player

        local bar: Frame = Instance.new("Frame")
        bar.Name = participant.Name
        bar.AnchorPoint = Vector2.new(1, 0)
        bar.BackgroundColor3 = PROGRESS_LINE_STROKE_COLOR
        bar.Size = UDim2.new(if prioritize then 2.5 else 1.5, 0, 0, indicatorHeight)
        bar.Position = UDim2.new(1, 0, 1, -indicatorHeight)
        bar.ZIndex = if prioritize then 3 else 2
        bar.Parent = progressLine

        local playerIcon = PlayerIcon.new(participant, UDim.new(0.5, 0))
        local icon = playerIcon:GetGuiObject()
        icon.AnchorPoint = Vector2.new(1, 0.5)
        icon.Size = UDim2.fromOffset(80, 80)
        icon.Position = UDim2.new(0, 40, 0.5, 0)
        playerIcon:Mount(bar)

        progressIndicators[participant] = bar
    end

    progressLine.Visible = true
    return progressIndicators, 1 - (indicatorHeight / progressLine.AbsoluteSize.Y)
end

function SledRaceScreen.closeProgressLine()
    progressLine.Visible = false

    if progressIndicators then
        for _, frame in pairs(progressIndicators) do
            frame:Destroy()
        end
        progressIndicators = nil
    end
end

function SledRaceScreen.setCoins(coins: number)
    coinCount.Text = coins :: string
    coinCount.Visible = true
end

function SledRaceScreen.closeCoins()
    coinCount.Visible = false
end

-------------------------------------------------------------------------------
-- Instructions
-------------------------------------------------------------------------------
do
    local exitButton = ExitButton.new()
    exitButton.Pressed:Connect(function()
        ScreenUtil.outDown(instructionsFrame)
        SharedMinigameScreen.openStartMenu()
    end)
    exitButton:Mount(instructionsFrame.Exit, true)
end

return SledRaceScreen
