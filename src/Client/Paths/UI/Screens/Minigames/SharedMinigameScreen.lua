local SharedMinigameScreen = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local Images = require(Paths.Shared.Images.Images)
local Binder = require(Paths.Shared.Binder)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local MinigameUtil = require(Paths.Shared.Minigames.MinigameUtil)
local MinigameConstants = require(Paths.Shared.Minigames.MinigameConstants)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local CameraController = require(Paths.Client.CameraController)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local Transitions = require(Paths.Client.UI.Screens.SpecialEffects.Transitions)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIController = require(Paths.Client.UI.UIController)
local DeviceUtil = require(Paths.Client.Utils.DeviceUtil)

local COUNTDOWN_TWEEN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local COUNTDOWN_BIND_KEY = "CountingDown:D"

local START_MENU_BACKGROUND_TRANSPARENCY = 0.3
local EXIT_BUTTON_TEXT = "Go Back"
local INSTRUCTIONS_BUTTON_TEXT = "Instructions"
local START_MENU_CAMERA_GIZMO_NAME = "StartMenu"

local PLAY_DELAY = 0.3

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local player = Players.LocalPlayer
local camera: Camera = Workspace.CurrentCamera

local templates = Paths.Templates.Minigames

local screens: Folder = Paths.UI.Minigames
local sharedScreens = screens.Shared

local startMenus: Frame = sharedScreens.StartMenus
local singlePlayerMenu = startMenus.SinglePlayer
local multiplayerMenu = startMenus.Multiplayer

local standingsFrame: Frame = sharedScreens.Standings
local resultsFrame: Frame = sharedScreens.Results

local statusFrame: Frame = sharedScreens.Status
local statusText: TextLabel = statusFrame.Text
local statusCounter: TextLabel = statusFrame.Counter

local playButton: TextButton = singlePlayerMenu.Play

local startInstructionButton = KeyboardButton.new()
local startExitButton = KeyboardButton.new()

local standingsClose = KeyboardButton.new()
local resultsClose = KeyboardButton.new()

local uiStateMachine = UIController.getStateMachine()

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function nextButton(button)
    button:SetColor(UIConstants.Colors.Buttons.NextTeal, true)
    button:SetText("Next", true)
    button:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
    return button
end

local function getScreenGui(): ScreenGui
    return screens[MinigameController.getMinigame()]
end

local function getLogo(): string
    return Images[MinigameController.getMinigame()].Logo
end

local function getCameraGizmo(): Model?
    local cameras = MinigameController.getMap():FindFirstChild("Cameras")
    if cameras then
        return cameras:FindFirstChild(START_MENU_CAMERA_GIZMO_NAME)
    end
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function SharedMinigameScreen.coreCountdown(timeLeft: number)
    local label: ImageLabel = getScreenGui().Countdown
    local initialLabelSize: UDim2 = Binder.bindFirst(label, "InitialSize", label.Size)
    label.Visible = false
    label.Image = Images[MinigameController.getMinigame()]["Countdown" .. (timeLeft - 1)] :: string
    label.Rotation = 90
    label.Size = UDim2.new()

    label.Visible = true
    TweenUtil.bind(label, COUNTDOWN_BIND_KEY, TweenService:Create(label, COUNTDOWN_TWEEN_INFO, { Rotation = 0, Size = initialLabelSize })).Completed
        :Connect(function(playbackState)
            -- RETURN: Previous tween was cancelled
            if playbackState ~= Enum.PlaybackState.Completed then
                return
            end

            TweenUtil.bind(
                label,
                COUNTDOWN_BIND_KEY,
                TweenService:Create(label, COUNTDOWN_TWEEN_INFO, {
                    Rotation = 90,
                    Size = UDim2.new(),
                })
            )
        end)
end

function SharedMinigameScreen.setStatusText(text: string?)
    statusText.Text = text
    statusText.Visible = text ~= nil
end

function SharedMinigameScreen.setStatusCounter(count: string | number | nil)
    statusCounter.Text = count
    statusCounter.Visible = count ~= nil
end

function SharedMinigameScreen.hideStatus()
    statusText.Visible = false
    statusCounter.Visible = false
end

function SharedMinigameScreen.openStartMenu()
    startMenus.Visible = true

    local actions: Frame
    if MinigameController.isMultiplayer() then
        multiplayerMenu.Visible = true
        actions = multiplayerMenu
    else
        startMenus.BackgroundTransparency = START_MENU_BACKGROUND_TRANSPARENCY

        local cameraGizmo = getCameraGizmo()
        if cameraGizmo then
            CameraController.viewCameraModel(cameraGizmo)
        end

        ScreenUtil.openBlur()
        singlePlayerMenu.Visible = true

        actions = singlePlayerMenu.Actions
    end

    startInstructionButton:Mount(actions.Instructions, true)
    startExitButton:Mount(actions.Exit, true)
end

function SharedMinigameScreen.closeStartMenu(temporary: true?)
    if MinigameController.isMultiplayer() then
        multiplayerMenu.Visible = false
        getScreenGui().Instructions.Visible = false
    else
        if not temporary then
            startMenus.Visible = false
            startMenus.BackgroundTransparency = 1
        end

        if getCameraGizmo() then
            CameraController.setPlayerControl()
            CameraController.alignCharacter()
        end

        singlePlayerMenu.Visible = false
        ScreenUtil.closeBlur()
    end
end

function SharedMinigameScreen.openStandings(scores: MinigameConstants.SortedScores)
    -- RETURN: Player is no longer in a minigame
    if not MinigameController.getMinigame() then
        return
    end

    local trash: { Frame } = {}

    for placement, info in pairs(scores) do
        local label: Frame = templates.PlayerScore:Clone()
        label.PlayerName.Text = info.Player.Name
        label.Medal.Image = Images.Minigames["Medal" .. placement] or ""
        label.Score.Text = MinigameUtil.formatScore(MinigameController.getMinigame(), info.Score)
        label.Parent = standingsFrame.List

        table.insert(trash, label)
    end

    standingsFrame.Logo.Image = getLogo()
    standingsFrame.Placement.Text = "You placed " .. MinigameController.getOwnPlacement(scores)

    ScreenUtil.inUp(standingsFrame)
    standingsClose.InternalRelease:Wait()

    -- Clean up
    for _, label in pairs(trash) do
        label:Destroy()
    end
end

function SharedMinigameScreen.openResults(values: { { Title: string, Icon: string?, Value: string | number } | string })
    -- RETURN: Player is no longer in a minigame
    if not MinigameController.getMinigame() then
        return
    end

    local trash: { Frame } = {}

    for _, info in pairs(values) do
        local label: Frame = templates.ResultValue:Clone()
        label.Title.Text = info.Title .. ":"
        label.Value.Text = info.Value
        label.Title.Icon.Image = info.Icon or ""
        label.Parent = resultsFrame.Values

        table.insert(trash, label)
    end

    resultsFrame.Logo.Image = getLogo()

    ScreenUtil.inUp(resultsFrame)
    resultsClose.InternalRelease:Wait()

    -- Clean up
    for _, label in pairs(trash) do
        label:Destroy()
    end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
-- Standings frame
do
    standingsClose = nextButton(standingsClose)
    standingsClose:Mount(standingsFrame.Next, true)
    standingsClose.Pressed:Connect(function()
        ScreenUtil.outDown(standingsFrame)
    end)
end

do
    -- Result frame
    resultsClose = nextButton(resultsClose)
    resultsClose:Mount(resultsFrame.Next, true)
    resultsClose.Pressed:Connect(function()
        ScreenUtil.outDown(resultsFrame)
    end)
end

-- Start menus
do
    playButton.Text = ("%s TO PLAY"):format(DeviceUtil.isMobile() and "TAP" or "CLICK")
    playButton.MouseButton1Down:Connect(function()
        Transitions.blink(function()
            SharedMinigameScreen.closeStartMenu()
        end, { HalfTweenTime = 0.5 })

        task.wait(math.max(0, PLAY_DELAY - (player:GetNetworkPing() * 2)))
        Remotes.fireServer("MinigameStarted")
    end)

    startExitButton = KeyboardButton.new()
    startExitButton:SetColor(UIConstants.Colors.Buttons.CloseRed, true)
    startExitButton:SetText(EXIT_BUTTON_TEXT, true)
    startExitButton:SetIcon(Images.Icons.Exit)
    startExitButton:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
    startExitButton.InternalRelease:Connect(function()
        Remotes.fireServer("MinigameExited")
    end)

    startInstructionButton = KeyboardButton.new()
    startInstructionButton:SetColor(UIConstants.Colors.Buttons.InstructionsOrange, true)
    startInstructionButton:SetText(INSTRUCTIONS_BUTTON_TEXT, true)
    startInstructionButton:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
    startInstructionButton:SetIcon(Images.Icons.Instructions)
    startInstructionButton.InternalRelease:Connect(function()
        SharedMinigameScreen.closeStartMenu(true)
        ScreenUtil.inUp(getScreenGui().Instructions)
    end)
end

-- Register ui states
do
    uiStateMachine:RegisterStateCallbacks(UIConstants.States.Minigame, nil, function()
        SharedMinigameScreen.closeStartMenu()
        SharedMinigameScreen.hideStatus()
    end)
end

return SharedMinigameScreen
