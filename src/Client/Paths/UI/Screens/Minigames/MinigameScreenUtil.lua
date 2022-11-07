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
local CameraController = require(Paths.Client.CameraController)

local COUNTDOWN_TWEEN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local COUNTDOWN_BIND_KEY = "CountingDown:D"

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local screenGuis: Folder = Paths.UI.Minigames
local camera: Camera = Workspace.CurrentCamera

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

return MinigameScreenUtil
