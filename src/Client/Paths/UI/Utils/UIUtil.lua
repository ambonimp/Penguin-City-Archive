local UIUtil = {}

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local Promise = require(Paths.Packages.promise)
local DescendantLooper = require(Paths.Shared.DescendantLooper)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)

--[[
    If we design a button to be at the top of the screen, it will still be so when we load in (even with the "roblox top bar")
    - Takes into account the AnchorPoint of the object (i.e., GuiObject centered on the screen will remain as such)
]]
function UIUtil.offsetGuiInset(guiObject: GuiObject)
    local guiInset = GuiService:GetGuiInset()
    local guiInsetUDim2 = UDim2.new(0, guiInset.X, 0, guiInset.Y * math.clamp(1 - guiObject.AnchorPoint.Y, 0, 1))
    guiObject.Position = guiObject.Position - guiInsetUDim2
end

-- Returns true if `pseudoState` is enabled by the current stack of the stateMachine
function UIUtil.getPseudoState(pseudoState: string)
    -- Get StateMachine, skirting around circular dependencies
    local stateMachine = require(Paths.Client.UI.UIController).getStateMachine()

    -- FALSE: Not in stack at all
    if not stateMachine:HasState(pseudoState) then
        return false
    end

    -- TRUE: At top
    if stateMachine:GetState() == pseudoState then
        return true
    end

    -- TRUE: Child at top
    local childStates = UIConstants.PseudoStates[pseudoState]
    if childStates then
        for _, childState in pairs(childStates) do
            if stateMachine:GetState() == childState then
                return true
            end
        end
    end

    return false
end

-- Will return a Promise that is resolved when we are in the HUD UIState and are in a Room Zone
function UIUtil.waitForHudAndRoomZone()
    -- Grab Dependencies in scope to avoid dependency issues
    local UIController = require(Paths.Client.UI.UIController)
    local ZoneController = require(Paths.Client.ZoneController)
    local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)

    return Promise.new(function(resolve, _reject, _onCancel)
        while true do
            local canShow = UIController.getStateMachine():GetState() == UIConstants.States.HUD
                and ZoneController.getCurrentZone().ZoneType == ZoneConstants.ZoneType.Room
            if canShow then
                break
            else
                task.wait()
            end
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

return UIUtil
