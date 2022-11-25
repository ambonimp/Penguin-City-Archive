local SharedMinigameScreen = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
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
local Sound = require(Paths.Shared.Sound)

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
local random = Random.new()

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local templates = Paths.Templates.Minigames

local screens: Folder = Paths.UI.Minigames
local sharedScreens = screens.Shared

local coreCountdownLabel: ImageLabel = sharedScreens.CoreCountdown

local startMenus: Frame = sharedScreens.StartMenus
local singlePlayerMenu = startMenus.SinglePlayer
local multiplayerMenu = startMenus.Multiplayer

local standingsFrame: Frame = sharedScreens.Standings
local resultsFrame: Frame = sharedScreens.Results

local statusFrame: Frame = sharedScreens.Status
local statusText: TextLabel = statusFrame.Text
local statusCounter: TextLabel = statusFrame.Counter

local playButton: TextButton = singlePlayerMenu.Play
local playButtonText: TextLabel = playButton.TextLabel
local playTween: Tween?

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
    local initialLabelSize: UDim2 = Binder.bindFirst(coreCountdownLabel, "InitialSize", coreCountdownLabel.Size)
    coreCountdownLabel.Visible = false
    coreCountdownLabel.Image = Images.Minigames["Countdown" .. (timeLeft - 1)] :: string
    coreCountdownLabel.Rotation = 90
    coreCountdownLabel.Size = UDim2.new()

    Sound.play("Countdown")

    coreCountdownLabel.Visible = true
    TweenUtil.bind(
        coreCountdownLabel,
        COUNTDOWN_BIND_KEY,
        TweenService:Create(coreCountdownLabel, COUNTDOWN_TWEEN_INFO, { Rotation = 0, Size = initialLabelSize })
    ).Completed
        :Connect(function(playbackState)
            -- RETURN: Previous tween was cancelled
            if playbackState ~= Enum.PlaybackState.Completed then
                return
            end

            TweenUtil.bind(
                coreCountdownLabel,
                COUNTDOWN_BIND_KEY,
                TweenService:Create(coreCountdownLabel, COUNTDOWN_TWEEN_INFO, {
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
        singlePlayerMenu.Logo.Image = getLogo()

        local cameraGizmo = getCameraGizmo()
        if cameraGizmo then
            CameraController.viewCameraModel(cameraGizmo)
        end

        ScreenUtil.openBlur()
        singlePlayerMenu.Visible = true

        actions = singlePlayerMenu.Actions

        playTween = TweenService:Create(
            playButtonText,
            TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In, -1, true, 0.4),
            { Size = UDim2.fromScale(1, 1.2) }
        )
        playTween.Completed:Connect(function()
            playButtonText.Size = UDim2.fromScale(1, 1)
            playTween = nil
        end)
        playTween:Play()
    end

    startInstructionButton:Mount(actions.Instructions, true)
    startExitButton:Mount(actions.Exit, true)
end

function SharedMinigameScreen.closeStartMenu(temporary: boolean?, callback: () -> ()?)
    local menu: Frame

    if startMenus.Visible then
        if MinigameController.isMultiplayer() then
            getScreenGui().Instructions.Visible = false
            menu = multiplayerMenu
        else
            if not temporary then
                startMenus.BackgroundTransparency = 1

                if getCameraGizmo() then
                    CameraController.setPlayerControl()
                    CameraController.alignCharacter()
                end

                playTween:Cancel()
                ScreenUtil.closeBlur()
            end

            menu = singlePlayerMenu
        end
    end

    if callback then
        callback()
    end

    startMenus.Visible = false
    menu.Visible = false
    Transitions.closeBlink()
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

    ScreenUtil.inUp(standingsFrame, true)
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

    ScreenUtil.inUp(resultsFrame, true)
    resultsClose.InternalRelease:Wait()

    -- Clean up
    for _, label in pairs(trash) do
        label:Destroy()
    end
end

function SharedMinigameScreen.textParticle(value: string, icon: string?, textColor: Color3?, iconColor: Color3?)
    icon = icon or ""
    iconColor = iconColor or Color3.new(1, 1, 1)
    textColor = textColor or Color3.new(1, 1, 1)

    local center: Vector3 = camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
    local initPosition = UDim2.fromOffset(center.X, center.Y) + UDim2.fromScale(random:NextNumber(-0.1, 0.1), random:NextNumber(0, -0.2))

    local particle: TextLabel = templates.TextParticle:Clone()
    local initSize = particle.Size
    local finalSize = UDim2.fromScale(0, 0)

    particle.Text = value
    particle.TextColor3 = textColor
    particle.Icon.Image = icon
    particle.Icon.ImageColor3 = iconColor
    particle.Parent = sharedScreens
    particle.Size = finalSize
    particle.Position = initPosition
    particle.Visible = true

    local offset = random:NextNumber(-0.05, 0.05)
    local sign = math.sign(offset)

    local openTween: Tween = TweenService:Create(particle, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Size = initSize + UDim2.fromScale(0.025, 0.025),
        Rotation = offset / 3,
        Position = initPosition + UDim2.fromScale(offset, -random:NextNumber(0.07, 0.12)),
    })

    openTween.Completed:Connect(function()
        local closeTween: Tween =
            TweenService:Create(particle, TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0.2), {
                Size = UDim2.fromScale(0, 0),
                Rotation = particle.Rotation + sign * 180,
                Position = particle.Position + UDim2.fromScale(offset * 2.5, random:NextNumber(0.05, 0.15)),
            })

        closeTween.Completed:Connect(function()
            particle:Destroy()
        end)

        closeTween:Play()
    end)

    openTween:Play()
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
-- Standings frame
do
    standingsClose = nextButton(standingsClose)
    standingsClose:Mount(standingsFrame.Next, true)
    standingsClose.Pressed:Connect(function()
        ScreenUtil.outDown(standingsFrame, true)
    end)
end

do
    -- Result frame
    resultsClose = nextButton(resultsClose)
    resultsClose:Mount(resultsFrame.Next, true)
    resultsClose.Pressed:Connect(function()
        ScreenUtil.outDown(resultsFrame, true)
    end)
end

-- Start menus
do
    playButtonText.Text = ("%s TO PLAY"):format(DeviceUtil.isMobile() and "TAP" or "CLICK")
    playButton.MouseButton1Down:Connect(function()
        Transitions.openBlink()

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
