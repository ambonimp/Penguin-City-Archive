local CoreGui = {}

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Maid = require(Paths.Packages.maid)

local DISABLE_CORE_GUI_TYPES = {
    Enum.CoreGuiType.Health,
    Enum.CoreGuiType.PlayerList,
}

local disableMaid = Maid.new()
local isEnabled = true

local function getTouchGui()
    return Players.LocalPlayer.PlayerGui:FindFirstChild("TouchGui") :: ScreenGui
end

function CoreGui.enable()
    -- RETURN: Already enabled
    if isEnabled then
        return
    end
    isEnabled = true

    disableMaid:Cleanup()

    -- Mobile Controls
    local touchGui = getTouchGui()
    if touchGui then
        touchGui.Enabled = true
    end
end

function CoreGui.disable()
    -- RETURN: Already disabled
    if not isEnabled then
        return
    end
    isEnabled = false

    -- Mobile Controls
    local touchGui = getTouchGui()
    if touchGui then
        touchGui.Enabled = false

        disableMaid:GiveTask(touchGui:GetPropertyChangedSignal("Enabled"):Connect(function()
            touchGui.Enabled = false
        end))
    end
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
