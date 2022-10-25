local UIUtil = {}

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local StateMachine = require(Paths.Shared.StateMachine)
local UIConstants = require(Paths.Client.UI.UIConstants)

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
function UIUtil.getPseudoState(pseudoState: string, stateMachine: StateMachine.StateMachine)
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

return UIUtil
