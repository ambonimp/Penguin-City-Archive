local ExitButton = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local Images = require(Paths.Shared.Images.Images)

function ExitButton.new()
    local button = KeyboardButton.new()

    button:SetColor(UIConstants.Colors.Buttons.CloseRed)
    button:SetIcon(Images.Icons.Close)
    button:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
    button:RoundOff()
    button:Outline(UIConstants.Offsets.ButtonOutlineThickness, Color3.fromRGB(255, 255, 255))

    return button
end

return ExitButton
