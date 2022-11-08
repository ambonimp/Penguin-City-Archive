local MinigameScreenUtil = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Images = require(Paths.Shared.Images.Images)
local Binder = require(Paths.Shared.Binder)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local MinigameController = require(Paths.Client.Minigames.MinigameController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local CameraController = require(Paths.Client.CameraController)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local MinigameUtil = require(Paths.Shared.Minigames.MinigameUtil)

local COUNTDOWN_TWEEN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local COUNTDOWN_BIND_KEY = "CountingDown:D"

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local camera: Camera = Workspace.CurrentCamera

local templates = Paths.Templates.Minigames

local screenGuis: Folder = Paths.UI.Minigames
local sharedScreenGui: ScreenGui = screenGuis.Shared

local standingsFrame: Frame = sharedScreenGui.Standings
local resultsFrame: Frame = sharedScreenGui.Results

local standingsClose = KeyboardButton.new()
local resultsClose = KeyboardButton.new()

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function getScreenGui(): ScreenGui
    return screenGuis[MinigameController.getMinigame()]
end

local function getCameraGizmo(name: string): Model?
    local cameras = MinigameController.getMap():FindFirstChild("Cameras")
    if cameras then
        return cameras:FindFirstChild(name)
    end
end

local function getLogo(): string
    return Images[MinigameController.getMinigame()].Logo
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function MinigameScreenUtil.openMenu()
    local screenGui = getScreenGui()

    if MinigameController.isMultiplayer() then
        -- TODO
    else
        local backdrop = screenGui:FindFirstChild("Backdrop")
        if backdrop then
            backdrop.Visible = true
        end

        local cameraGizmo = getCameraGizmo("SinglePlayerMenu")
        if cameraGizmo then
            camera.CameraType = Enum.CameraType.Scriptable
            camera.CFrame = cameraGizmo.WorldPivot
        end

        screenGui.SinglePlayerMenu.Visible = true
        ScreenUtil.openBlur()
    end
end

function MinigameScreenUtil.closeMenu()
    local screenGui = getScreenGui()

    if MinigameController.isMultiplayer() then
        -- TODO
    else
        if getCameraGizmo("SinglePlayerMenu") then
            CameraController.setPlayerControl()
            CameraController.alignCharacter()
        end

        local backdrop = screenGui:FindFirstChild("Backdrop")
        if backdrop then
            backdrop.Visible = false
        end

        screenGui.SinglePlayerMenu.Visible = false
        ScreenUtil.closeBlur()
    end
end

function MinigameScreenUtil.openStandings()
    local trash: { Frame } = {}

    for placement, info in pairs(MinigameController.getScores()) do
        local label: Frame = templates.PlayerScore:Clone()
        label.PlayerName.Text = info.Player.Name
        label.Medal.Image = Images.Minigames["Medal" .. placement] or ""
        label.Score.Text = MinigameUtil.formatScore(MinigameController.getMinigame(), info.Score)
        label.Parent = standingsFrame.List

        table.insert(trash, label)
    end

    standingsFrame.Logo.Image = getLogo()
    standingsFrame.Placement.Text = "You placed " .. MinigameController.getOwnPlacement()

    ScreenUtil.inUp(standingsFrame)
    standingsClose.InternalRelease:Wait()

    -- Clean up
    for _, label in pairs(trash) do
        label:Destroy()
    end
end

-- TODO: Add stamps
function MinigameScreenUtil.openResults(values: { { Title: string, Icon: string?, Value: string | number } | string })
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

function MinigameScreenUtil.coreCountdown(timeLeft: number)
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

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
standingsClose:SetColor(UIConstants.Colors.Buttons.NextTeal, true)
standingsClose:SetText("Next", true)
standingsClose:Mount(standingsFrame.Next, true)
standingsClose:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
standingsClose.Pressed:Connect(function()
    ScreenUtil.outDown(standingsFrame)
end)

resultsClose:SetColor(UIConstants.Colors.Buttons.NextTeal, true)
resultsClose:SetText("Next", true)
resultsClose:Mount(resultsFrame.Next, true)
resultsClose:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
resultsClose.Pressed:Connect(function()
    ScreenUtil.outDown(resultsFrame)
end)

return MinigameScreenUtil
