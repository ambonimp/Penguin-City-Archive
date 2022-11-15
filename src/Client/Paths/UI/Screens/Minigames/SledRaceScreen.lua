local SledRaceScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local SharedMinigameScreen = require(Paths.Client.UI.Screens.Minigames.SharedMinigameScreen)

local PROGRESS_LINE_STROKE_COLOR = Color3.fromRGB(26, 26, 26)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local random = Random.new()

local player = Players.LocalPlayer

local screen: ScreenGui = Paths.UI.Minigames.SledRace
local instructionsFrame: Frame = screen.Instructions

local progressLine: Frame = screen.ProgressLine
local progressIndicators: { [Player]: Frame }?

local coinCount: TextLabel = screen.Coins
local coinCountSize: UDim2 = coinCount.Size

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
function SledRaceScreen.openProgressLine(indicatorHeight: number): ({ [Player]: Frame }, number)
    progressIndicators = {}

    for _, participant in pairs(MinigameController.getParticpants()) do
        local prioritize = participant == player

        local bar: Frame = Instance.new("Frame")
        bar.AnchorPoint = Vector2.new(1, 0)
        bar.BackgroundColor3 = PROGRESS_LINE_STROKE_COLOR
        bar.Size = UDim2.new(if prioritize then 1.5 else 1, 0, 0, indicatorHeight)
        bar.Position = UDim2.new(1, 0, 1, -indicatorHeight)
        bar.ZIndex = if prioritize then 3 else 2
        bar.Parent = progressLine

        local icon: ImageLabel = Instance.new("ImageLabel")
        icon.Image = Players:GetUserThumbnailAsync(participant.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        icon.BackgroundColor3 =
            Color3.fromHSV(random:NextInteger(170, 270) / 360, random:NextInteger(0, 50) / 100, random:NextInteger(85, 100) / 100)
        icon.AnchorPoint = Vector2.new(1, 0.5)
        icon.Size = UDim2.fromOffset(80, 80)
        icon.Position = UDim2.new(0, 40, 0.5, 0)
        icon.ZIndex = if prioritize then 4 else 3
        icon.Parent = bar

        local roundedCorners: UICorner = Instance.new("UICorner")
        roundedCorners.CornerRadius = UDim.new(0.5, 0)
        roundedCorners.Parent = icon

        local stroke: UIStroke = Instance.new("UIStroke")
        stroke.Color = PROGRESS_LINE_STROKE_COLOR
        stroke.Thickness = 4
        stroke.Parent = icon

        progressIndicators[participant] = bar
    end

    progressLine.Visible = true
    return progressIndicators, 1 - (indicatorHeight / progressLine.AbsoluteSize.Y)
end

function SledRaceScreen.closeProgressLine()
    progressLine.Visible = false

    for _, frame in pairs(progressIndicators) do
        frame:Destroy()
    end
    progressIndicators = nil
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
