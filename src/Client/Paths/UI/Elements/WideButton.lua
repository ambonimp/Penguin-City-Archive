local WideButton = {}

local KeyboardButton = require(script.Parent.KeyboardButton)
local UIConstants = require(script.Parent.Parent.UIConstants)

local DEBOUNCE = 0.2
local CORNER_RADIUS = UDim.new(0.15, 0)

function WideButton.new(text: string)
    local wideButton = KeyboardButton.new()
    wideButton:SetPressedDebounce(DEBOUNCE)
    wideButton:SetText(text)
    wideButton:SetCornerRadius(CORNER_RADIUS)

    return wideButton
end

function WideButton.blue(text: string)
    local wideButton = WideButton.new(text)
    wideButton:SetColor(UIConstants.Colors.Buttons.PenguinBlue, true)
    wideButton:SetTextColor(UIConstants.Colors.Buttons.DarkPenguinBlue, true)

    return wideButton
end

function WideButton.green(text: string)
    local wideButton = WideButton.new(text)
    wideButton:SetColor(UIConstants.Colors.Buttons.NextGreen, true)
    wideButton:SetTextColor(UIConstants.Colors.Misc.White, true)

    return wideButton
end

function WideButton.red(text: string)
    local wideButton = WideButton.new(text)
    wideButton:SetColor(UIConstants.Colors.Buttons.CloseRed, true)
    wideButton:SetTextColor(UIConstants.Colors.Misc.White, true)

    return wideButton
end

return WideButton
