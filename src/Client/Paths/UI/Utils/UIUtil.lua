local UIUtil = {}

local GuiService = game:GetService("GuiService")

--[[
    If we design a button to be at the top of the screen, it will still be so when we load in (even with the "roblox top bar")
    - Takes into account the AnchorPoint of the object (i.e., GuiObject centered on the screen will remain as such)
]]
function UIUtil.offsetGuiInset(guiObject: GuiObject)
    local guiInset = GuiService:GetGuiInset()
    local guiInsetUDim2 = UDim2.new(0, guiInset.X, 0, (1 - guiInset.Y) * guiObject.AnchorPoint.Y)
    guiObject.Position -= guiInsetUDim2
end

return UIUtil
