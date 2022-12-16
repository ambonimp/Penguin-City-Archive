local UIActions = {}

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIController = require(Paths.Client.UI.UIController)
local UIConstants = require(Paths.Client.UI.UIConstants)
local Maid = require(Paths.Packages.maid)
local Queue = require(Paths.Shared.Queue)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local NotificationIcon = require(Paths.Client.UI.Elements.NotificationIcon)
local Sound = require(Paths.Shared.Sound)
local Scope = require(Paths.Shared.Scope)

local notificationIconsByGuiObject: { [GuiObject]: typeof(NotificationIcon.new()) } = {}
local focalPointScope = Scope.new()

-------------------------------------------------------------------------------
-- UI State Wrappers
-------------------------------------------------------------------------------

-- Pulls up the results screen via a uiStateMachine push
function UIActions.displayResults(
    logoId: string,
    values: { { Name: string, Value: any, Icon: string? } },
    nextCallback: (() -> nil)?,
    stampData: { [string]: number }?
)
    UIController.getStateMachine():Push(UIConstants.States.Results, {
        LogoId = logoId,
        Values = values,
        NextCallback = nextCallback,
        StampData = stampData,
    })
end

function UIActions.prompt(
    title: string?,
    description: string?,
    middleMounter: ((parent: GuiObject, maid: typeof(Maid.new())) -> nil)?,
    leftButton: { Text: string?, Icon: string?, Color: Color3?, Callback: (() -> nil)? }?,
    rightButton: { Text: string?, Icon: string?, Color: Color3?, Callback: (() -> nil)? }?,
    background: { Blur: boolean?, Image: string?, DoRotate: boolean? }?
)
    Queue.addTask(UIActions, function()
        UIController.getStateMachine():Push(UIConstants.States.GenericPrompt, {
            Title = title,
            Description = description,
            MiddleMounter = middleMounter,
            LeftButton = leftButton,
            RightButton = rightButton,
            Background = background,
        })

        while UIController.getStateMachine():HasState(UIConstants.States.GenericPrompt) do
            task.wait()
        end
    end)
end

function UIActions.showStampInfo(stampId: string, progress: number?)
    UIController.getStateMachine():Push(UIConstants.States.StampInfo, {
        StampId = stampId,
        Progress = progress,
    })
end

--[[
    Puts a focal point on the screen at a position - this is the same as thats used in the tutorial!

    Returns a callback that when invoked will hide the focal point from this call only!
]]
function UIActions.focalPoint(positionOrGuiObject: UDim2 | GuiObject, size: UDim2?)
    local scopeId = focalPointScope:NewScope()

    UIController.getStateMachine():Remove(UIConstants.States.FocalPoint) -- Remove any old focal points
    UIController.getStateMachine():Push(UIConstants.States.FocalPoint, {
        PositionOrGuiObject = positionOrGuiObject,
        Size = size,
    })

    return function()
        if focalPointScope:Matches(scopeId) then
            UIController.getStateMachine():Remove(UIConstants.States.FocalPoint)
        end
    end
end

-------------------------------------------------------------------------------
-- Notifications
-------------------------------------------------------------------------------

function UIActions.sendRobloxNotification(configTable: {
    Title: string?,
    Text: string?,
    Icon: string?,
    Duration: number?,
    Callback: (() -> any)?,
    Button1: string?,
    Button2: string?,
})
    configTable.Title = configTable.Title or "Notification"
    configTable.Text = configTable.Text or ""

    if configTable.Callback then
        local callbackFunction = configTable.Callback
        local bindableFunction = Instance.new("BindableFunction")
        bindableFunction.OnInvoke = callbackFunction

        configTable.Callback = bindableFunction :: nil
    end

    StarterGui:SetCore("SendNotification", configTable)
    Sound.play("Notification")
end

--[[
    Adds a notification icon to GuiObject. If one already exists, will increment it. Defaults to top right corner.

    Returns NotificationIcon
]]
function UIActions.addNotificationIcon(guiObject: GuiObject, anchorPoint: Vector2?)
    anchorPoint = anchorPoint or Vector2.new(1, 0)

    -- Get Notification Icon
    local notificationIcon = notificationIconsByGuiObject[guiObject]
    if not notificationIcon then
        notificationIcon = NotificationIcon.new()
        notificationIconsByGuiObject[guiObject] = notificationIcon

        notificationIcon:Mount(guiObject, anchorPoint)

        notificationIcon:GetMaid():GiveTask(InstanceUtil.onDestroyed(guiObject, function()
            notificationIcon:Destroy()
            notificationIconsByGuiObject[guiObject] = nil
        end))
    end

    return notificationIcon
end

function UIActions.getNotificationIcon(guiObject: GuiObject)
    return notificationIconsByGuiObject[guiObject] or nil
end

-- Removes NotificationIcon from GuiObject
function UIActions.clearNotificationIcon(guiObject: GuiObject)
    local notificationIcon = notificationIconsByGuiObject[guiObject]
    if notificationIcon then
        notificationIcon:Destroy()
        notificationIconsByGuiObject[guiObject] = nil
    end
end

return UIActions
