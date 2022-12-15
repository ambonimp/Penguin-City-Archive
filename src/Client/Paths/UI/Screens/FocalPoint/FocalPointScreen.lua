local FocalPointScreen = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIController = require(Paths.Client.UI.UIController)
local Maid = require(Paths.Packages.maid)
local ScreenUtil = require(Paths.Client.UI.Utils.ScreenUtil)
local ExitButton = require(Paths.Client.UI.Elements.ExitButton)
local UIUtil = require(Paths.Client.UI.Utils.UIUtil)
local UIConstants = require(Paths.Client.UI.UIConstants)
local UIScaleController = require(Paths.Client.UI.Scaling.UIScaleController)
local TweenUtil = require(Paths.Shared.Utils.TweenUtil)

local DEFAULT_SIZE = UDim2.fromOffset(250, 250)
local SCREEN_GUI_DISPLAY_ORDER = 1000
local COLOR = Color3.fromRGB(38, 71, 118)
local BIG_OFFSET = 10000
local TWEEN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local screenGui: ScreenGui?

function FocalPointScreen.Init()
    -- Register UIState
    do
        UIController.registerStateScreenCallbacks(UIConstants.States.FocalPoint, {
            Boot = FocalPointScreen.boot,
            Shutdown = FocalPointScreen.shutdown,
            Maximize = FocalPointScreen.maximize,
            Minimize = FocalPointScreen.minimize,
        })
    end
end

function FocalPointScreen.boot(data: table)
    -- Read Data
    local position: UDim2 = data.Position
    local size: UDim2 = data.Size or DEFAULT_SIZE

    --#region Create UI
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FocalPoint"
    screenGui.DisplayOrder = SCREEN_GUI_DISPLAY_ORDER
    screenGui.Parent = Paths.UI

    local focalPoint = Instance.new("Frame")
    focalPoint.Name = "focalPoint"
    focalPoint.AnchorPoint = Vector2.new(0.5, 0.5)
    focalPoint.BackgroundTransparency = 1
    focalPoint.Position = position
    focalPoint.Parent = screenGui

    local viewport = Instance.new("ImageLabel")
    viewport.Name = "viewport"
    viewport.Image = "rbxassetid://11825341688"
    viewport.ImageTransparency = 0.4
    viewport.BackgroundTransparency = 1
    viewport.BorderSizePixel = 0
    viewport.Size = UDim2.fromScale(1, 1)
    viewport.Parent = focalPoint

    local uIScale = Instance.new("UIScale")
    uIScale.Name = "uIScale"
    uIScale.Parent = focalPoint

    local top = Instance.new("Frame")
    top.Name = "top"
    top.AnchorPoint = Vector2.new(0.5, 1)
    top.BackgroundColor3 = COLOR
    top.BackgroundTransparency = 0.4
    top.BorderSizePixel = 0
    top.Position = UDim2.fromScale(0.5, 0)
    top.Size = UDim2.new(1, 0, 0, BIG_OFFSET)
    top.Parent = focalPoint

    local bottom = Instance.new("Frame")
    bottom.Name = "bottom"
    bottom.AnchorPoint = Vector2.new(0.5, 0)
    bottom.BackgroundColor3 = COLOR
    bottom.BackgroundTransparency = 0.4
    bottom.BorderSizePixel = 0
    bottom.Position = UDim2.fromScale(0.5, 1)
    bottom.Size = UDim2.new(1, 0, 0, BIG_OFFSET)
    bottom.Parent = focalPoint

    local left = Instance.new("Frame")
    left.Name = "left"
    left.AnchorPoint = Vector2.new(1, 0.5)
    left.BackgroundColor3 = COLOR
    left.BackgroundTransparency = 0.4
    left.BorderSizePixel = 0
    left.Position = UDim2.fromScale(0, 0.5)
    left.Size = UDim2.fromOffset(BIG_OFFSET, BIG_OFFSET)
    left.Parent = focalPoint

    local right = Instance.new("Frame")
    right.Name = "right"
    right.AnchorPoint = Vector2.new(0, 0.5)
    right.BackgroundColor3 = COLOR
    right.BackgroundTransparency = 0.4
    right.BorderSizePixel = 0
    right.Position = UDim2.fromScale(1, 0.5)
    right.Size = UDim2.fromOffset(BIG_OFFSET, BIG_OFFSET)
    right.Parent = focalPoint
    --#endregion

    -- Animate in new thread so `maximize` has been called
    task.defer(function()
        local viewportSize = Workspace.CurrentCamera.ViewportSize
        local uiScale = UIScaleController.getScale()
        local startSize = (math.max(viewportSize.X, viewportSize.Y) * 2) / uiScale

        focalPoint.Size = UDim2.fromOffset(startSize, startSize)
        TweenUtil.tween(focalPoint, TWEEN_INFO, {
            Size = size,
        })
    end)
end

function FocalPointScreen.shutdown()
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end
end

function FocalPointScreen.maximize()
    if screenGui then
        screenGui.Enabled = true
    end
end

function FocalPointScreen.minimize()
    if screenGui then
        screenGui.Enabled = false
    end
end

return FocalPointScreen
