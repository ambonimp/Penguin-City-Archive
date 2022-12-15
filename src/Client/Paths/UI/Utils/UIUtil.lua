local UIUtil = {}

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local Promise = require(Paths.Packages.promise)
local DescendantLooper = require(Paths.Shared.DescendantLooper)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local UDImUtil = require(Paths.Shared.Utils.UDimUtil)

--[[
    If we design a button to be at the top of the screen, it will still be so when we load in (even with the "roblox top bar")
    - Takes into account the AnchorPoint of the object (i.e., GuiObject centered on the screen will remain as such)
]]
function UIUtil.offsetGuiInset(guiObject: GuiObject)
    local guiInset = GuiService:GetGuiInset()
    local guiInsetUDim2 = UDim2.new(0, guiInset.X, 0, guiInset.Y * math.clamp(1 - guiObject.AnchorPoint.Y, 0, 1))
    guiObject.Position = guiObject.Position - guiInsetUDim2
end

--[[
    Returns true if `pseudoState` is enabled by the current stack of the stateMachine

    We default query the UIStateMachine to get the state at the top of the stack - you can pass `topState` to simulate that state being on top
]]
function UIUtil.getPseudoState(pseudoState: string, topState: string?)
    -- Get StateMachine, skirting around circular dependencies
    local stateMachine = require(Paths.Client.UI.UIController).getStateMachine()

    topState = topState or stateMachine:GetStack()

    -- TRUE: At top
    if topState == pseudoState then
        return true
    end

    -- TRUE: Child at top
    local childStates = UIConstants.PseudoStates[pseudoState]
    if childStates then
        for _, childState in pairs(childStates) do
            if topState == childState then
                return true
            end
        end
    end

    return false
end

--[[
    Will return a Promise that is resolved when we are in the HUD UIState and are in a Room Zone

    - `timeSeconds`: If passed, will ensure this state has been held for `timeSeconds` before resolving
]]
function UIUtil.waitForHudAndRoomZone(timeSeconds: number?)
    -- Grab Dependencies in scope to avoid dependency issues
    local UIController = require(Paths.Client.UI.UIController)
    local ZoneController = require(Paths.Client.Zones.ZoneController)
    local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)

    return Promise.new(function(resolve, _reject, _onCancel)
        local beenAbleToShowSince: number?

        while true do
            local canShow = UIController.getStateMachine():GetState() == UIConstants.States.HUD
                and ZoneController.getCurrentZone().ZoneCategory == ZoneConstants.ZoneCategory.Room
            if canShow then
                beenAbleToShowSince = beenAbleToShowSince or tick()
                if not timeSeconds or (tick() > beenAbleToShowSince + timeSeconds) then
                    break
                end
            else
                beenAbleToShowSince = nil
            end

            task.wait()
        end
        resolve()
    end)
end

--[[
    Will add `offset` to the ZIndex of any `GuiObject` under `ancestor` (including itself).

    Useful for pushing a whole UI Screen up to the front
]]
function UIUtil.offsetZIndex(ancestor: Instance, offset: number, offsetFutureInstances: boolean?)
    offsetFutureInstances = offsetFutureInstances and true or false

    -- Loop ancestor, offsetting the ZIndex of all present and future GuiObjects
    local maid = DescendantLooper.add(function(instance)
        return instance:IsA("GuiObject")
    end, function(guiObject: GuiObject)
        guiObject.ZIndex = guiObject.ZIndex + offset
    end, { ancestor }, not offsetFutureInstances)

    -- Manage Cleanup
    InstanceUtil.onDestroyed(ancestor, function()
        maid:Destroy()
    end)
end

--[[
    Converts any UI design by Offset into Scale; useful for BillboardGui.

    - If `resolution` is not passed, will infer it from the passed `guiObject`.
    - `guiObject` has its size set to `UDim2.fromScale(1, 1)`, and all descendants infer from this.
]]
function UIUtil.convertToScale(guiObject: GuiObject, resolution: UDim2?)
    -- Get Resolution
    if not resolution then
        resolution = guiObject.Size
    end

    -- ERROR: Bad resolution
    if (resolution.X.Offset == 0) and (resolution.Y.Offset == 0) then
        error("Resolution has no Offset!")
    end

    local function recurse(instance: Instance, scaleContext: UDim2)
        for _, child: GuiObject | UICorner in pairs(instance:GetChildren()) do
            if child:IsA("GuiObject") then
                local scaleSize = UDim2.new(
                    child.Size.X.Scale + (child.Size.X.Offset / resolution.X.Offset) / scaleContext.X.Scale,
                    0,
                    child.Size.Y.Scale + (child.Size.Y.Offset / resolution.Y.Offset) / scaleContext.Y.Scale,
                    0
                )
                child.Size = scaleSize
                recurse(child, UDImUtil.multiplyUDim2s(scaleContext, scaleSize))
            elseif child:IsA("UICorner") then
                local scaleCornerRadius = UDim.new(child.Size.Scale + (child.Size.Offset / resolution.X) / scaleContext.X.Scale, 0)
                child.CornerRadius = scaleCornerRadius
            end
        end
    end

    guiObject.Size = UDim2.fromScale(1, 1)
    recurse(guiObject, UDim2.fromScale(1, 1))
end

return UIUtil
