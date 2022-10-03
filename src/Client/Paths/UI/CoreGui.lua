local CoreGui = {}

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local DISABLE_CORE_GUI_TYPES = {
    Enum.CoreGuiType.Health,
    Enum.CoreGuiType.PlayerList,
}

local function getTouchGui()
    return Players.LocalPlayer.PlayerGui.TouchGui :: ScreenGui
end

function CoreGui.enable()
    -- Mobile Controls
    getTouchGui().Enabled = true
end

function CoreGui.disable(ignoreMobileControls: boolean?)
    -- Mobile Controls
    if not ignoreMobileControls then
        getTouchGui().Enabled = false
    end
end

-- Global disbables
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
