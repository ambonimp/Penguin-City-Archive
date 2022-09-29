local UIUtil = {}

local GuiService = game:GetService("GuiService")

function UIUtil.offsetGuiInset(guiObject: GuiObject)
    local guiInset = GuiService:GetGuiInset()
    local guiInsetUDim2 = UDim2.new(0, guiInset.X, 0, guiInset.Y)
    guiObject.Position -= guiInsetUDim2
end

return UIUtil
