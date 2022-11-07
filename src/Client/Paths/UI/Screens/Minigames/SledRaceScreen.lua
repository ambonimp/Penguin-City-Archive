local SledRaceScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Images = require(Paths.Shared.Images.Images)
local Remotes = require(Paths.Shared.Remotes)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local MinigameScreenUtil = require(Paths.Client.UI.Screens.Minigames.MinigameScreenUtil)
local Transitions = require(Paths.Client.UI.Screens.SpecialEffects.Transitions)

local EXIT_BUTTON_TEXT = "Go Back"
local INSTRUCTIONS_BUTTON_TEXT = "Instructions"

local START_PAUSE_LENGTH = 0.3

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local player = Players.LocalPlayer

local screen: ScreenGui = Paths.UI.Minigames.SledRace
local instructionsFrame: Frame = screen.Instructions
local singlePlayerMenu: Frame = screen.SinglePlayerMenu
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
-- Single player start
-------------------------------------------------------------------------------
do
    singlePlayerMenu.Play.MouseButton1Down:Connect(function()
        Transitions.blink(function()
            MinigameScreenUtil.closeMenu()
        end, { HalfTweenTime = 0.5 })

        task.wait(math.max(0, START_PAUSE_LENGTH - (player:GetNetworkPing() * 2)))
        Remotes.fireServer("MinigameStarted")
    end)

    local exitButton = KeyboardButton.new()
    exitButton:SetColor(UIConstants.Colors.Buttons.CloseRed, true)
    exitButton:SetText(EXIT_BUTTON_TEXT, true)
    exitButton:Mount(singlePlayerMenu.Actions.Exit, true)
    exitButton:SetIcon(Images.Icons.Exit)
    exitButton:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
    exitButton.InternalRelease:Connect(function()
        Remotes.fireServer("MinigameExited")
        MinigameScreenUtil.closeMenu()
    end)

    local instructionsButton = KeyboardButton.new()
    instructionsButton:SetColor(UIConstants.Colors.Buttons.InstructionsOrange, true)
    instructionsButton:SetText(INSTRUCTIONS_BUTTON_TEXT, true)
    instructionsButton:Mount(singlePlayerMenu.Actions.Instructions, true)
    instructionsButton:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
    instructionsButton:SetIcon(Images.Icons.Instructions)
    instructionsButton.InternalRelease:Connect(function()
        singlePlayerMenu.Visible = false
        ScreenUtil.inUp(instructionsFrame)
    end)
end

-------------------------------------------------------------------------------
-- Instructions
-------------------------------------------------------------------------------
do
    local exitButton = ExitButton.new()
    exitButton.Pressed:Connect(function()
        ScreenUtil.outDown(instructionsFrame)
        if not MinigameController.isMultiplayer() then
            singlePlayerMenu.Visible = true
        end
    end)
    exitButton:Mount(instructionsFrame.Exit, true)
end

return SledRaceScreen
