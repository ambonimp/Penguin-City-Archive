local CoreGui = {}

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local DISABLE_CORE_GUI_TYPES = {
    Enum.CoreGuiType.Health,
    Enum.CoreGuiType.PlayerList,
}

local isEnabled = true

function CoreGui.enable()
    -- RETURN: Already enabled
    if isEnabled then
        return
    end
    isEnabled = true

    -- Mobile Controls
    GuiService.TouchControlsEnabled = true
end

function CoreGui.disable()
    -- RETURN: Already disabled
    if not isEnabled then
        return
    end
    isEnabled = false

    -- Mobile Controls
    GuiService.TouchControlsEnabled = false
end

-- Global disables
do
    for _, coreGuiType in pairs(DISABLE_CORE_GUI_TYPES) do
        StarterGui:SetCoreGuiEnabled(coreGuiType, false)
    end
end

-- Lock Mobile rotation
do
    Players.LocalPlayer.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
end

return CoreGui
