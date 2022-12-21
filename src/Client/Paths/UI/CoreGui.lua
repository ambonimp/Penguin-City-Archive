local CoreGui = {}

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local StarterGui = game:GetService("StarterGui")
local ZoneConstants = require(Paths.Shared.Zones.ZoneConstants)
local Toggle = require(Paths.Shared.Toggle)

local DISABLE_CORE_GUI_TYPES = {
    Enum.CoreGuiType.Health,
    Enum.CoreGuiType.PlayerList,
    Enum.CoreGuiType.Backpack,
}

local enabledToggle = Toggle.new(true, function(isEnabled)
    GuiService.TouchControlsEnabled = isEnabled
end)

function CoreGui.enable(scope: string)
    enabledToggle:Set(true, scope)
end

function CoreGui.disable(scope: string)
    enabledToggle:Set(false, scope)
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

-- Disable Character reset : https://devforum.roblox.com/t/how-to-completely-restart-the-game-for-a-player-when-he-resets-its-character/1435353/5
do
    local resetBindable = Instance.new("BindableEvent")
    resetBindable.Event:Connect(function()
        -- Circular Dependencies
        local ZoneController = require(Paths.Client.Zones.ZoneController)

        ZoneController.teleportToDefaultZone(ZoneConstants.TravelMethod.RobloxReset)
    end)

    task.spawn(function()
        local success = false
        repeat
            task.wait(1)
            success = pcall(function()
                game:GetService("StarterGui"):SetCore("ResetButtonCallback", resetBindable)
            end)
        until success
    end)
end

return CoreGui
