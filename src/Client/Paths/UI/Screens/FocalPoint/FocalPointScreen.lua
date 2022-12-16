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
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)

local DEFAULT_SIZE = UDim2.fromOffset(250, 250)
local SCREEN_GUI_DISPLAY_ORDER = 2
local COLOR = Color3.fromRGB(38, 71, 118)
local BIG_OFFSET = 10000
local TWEEN_INFO_IN = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_INFO_SHOW_HIDE = TweenInfo.new(0.2, Enum.EasingStyle.Linear)
local TRANSPARENCY = 0.2

local screenGui: ScreenGui?

local currentState: { FocalPoint: Frame, Size: UDim2, PositionOrGuiObject: GuiObject | UDim2 }
local bootMaid = Maid.new()

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

local function updateFocalPointPosition()
    if not currentState then
        return
    end

    local position: UDim2
    if typeof(currentState.PositionOrGuiObject) == "UDim2" then
        position = currentState.PositionOrGuiObject
    else
        local middlePosition = currentState.PositionOrGuiObject.AbsolutePosition + currentState.PositionOrGuiObject.AbsoluteSize / 2
        position = UDim2.fromOffset(middlePosition.X, middlePosition.Y)
    end

    currentState.FocalPoint.Position = position
end

function FocalPointScreen.boot(data: table)
    -- Read Data
    local positionOrGuiObject: UDim2 | GuiObject = data.PositionOrGuiObject
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
    focalPoint.Parent = screenGui

    local viewport = Instance.new("ImageLabel")
    viewport.Name = "viewport"
    viewport.Image = "rbxassetid://11825341688"
    viewport.ImageTransparency = TRANSPARENCY
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
    top.BackgroundTransparency = TRANSPARENCY
    top.BorderSizePixel = 0
    top.Position = UDim2.fromScale(0.5, 0)
    top.Size = UDim2.new(1, 0, 0, BIG_OFFSET)
    top.Parent = focalPoint

    local bottom = Instance.new("Frame")
    bottom.Name = "bottom"
    bottom.AnchorPoint = Vector2.new(0.5, 0)
    bottom.BackgroundColor3 = COLOR
    bottom.BackgroundTransparency = TRANSPARENCY
    bottom.BorderSizePixel = 0
    bottom.Position = UDim2.fromScale(0.5, 1)
    bottom.Size = UDim2.new(1, 0, 0, BIG_OFFSET)
    bottom.Parent = focalPoint

    local left = Instance.new("Frame")
    left.Name = "left"
    left.AnchorPoint = Vector2.new(1, 0.5)
    left.BackgroundColor3 = COLOR
    left.BackgroundTransparency = TRANSPARENCY
    left.BorderSizePixel = 0
    left.Position = UDim2.fromScale(0, 0.5)
    left.Size = UDim2.fromOffset(BIG_OFFSET, BIG_OFFSET)
    left.Parent = focalPoint

    local right = Instance.new("Frame")
    right.Name = "right"
    right.AnchorPoint = Vector2.new(0, 0.5)
    right.BackgroundColor3 = COLOR
    right.BackgroundTransparency = TRANSPARENCY
    right.BorderSizePixel = 0
    right.Position = UDim2.fromScale(1, 0.5)
    right.Size = UDim2.fromOffset(BIG_OFFSET, BIG_OFFSET)
    right.Parent = focalPoint
    --#endregion

    -- Default hidden
    InstanceUtil.hide(screenGui:GetDescendants())

    currentState = {
        PositionOrGuiObject = positionOrGuiObject,
        FocalPoint = focalPoint,
        Size = size,
    }

    -- Position
    updateFocalPointPosition()

    -- If GuiObject moves, so do we!
    if not (typeof(positionOrGuiObject) == "UDim2") then
        bootMaid:GiveTask(function()
            positionOrGuiObject.Changed:Connect(updateFocalPointPosition)
        end)
    end
end

function FocalPointScreen.shutdown()
    bootMaid:Cleanup()

    local thisScreenGui = screenGui
    if thisScreenGui then
        task.delay(TWEEN_INFO_SHOW_HIDE.Time, function()
            thisScreenGui:Destroy()

            if screenGui == thisScreenGui then
                screenGui = nil
            end
        end)
    end
end

function FocalPointScreen.maximize()
    screenGui.Enabled = true
    InstanceUtil.show(screenGui:GetDescendants(), TWEEN_INFO_SHOW_HIDE)

    -- Animate
    local viewportSize = Workspace.CurrentCamera.ViewportSize
    local uiScale = UIScaleController.getScale()
    local startSize = (math.max(viewportSize.X, viewportSize.Y) * 2) / uiScale

    currentState.FocalPoint.Size = UDim2.fromOffset(startSize, startSize)
    TweenUtil.tween(currentState.FocalPoint, TWEEN_INFO_IN, {
        Size = currentState.Size,
    })
end

function FocalPointScreen.minimize()
    InstanceUtil.hide(screenGui:GetDescendants(), TWEEN_INFO_SHOW_HIDE)
end

return FocalPointScreen
