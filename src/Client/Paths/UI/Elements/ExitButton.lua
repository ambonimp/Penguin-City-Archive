local ExitButton = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)
local UIConstants = require(script.Parent.Parent.UIConstants)
local KeyboardButton = require(script.Parent.KeyboardButton)

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
