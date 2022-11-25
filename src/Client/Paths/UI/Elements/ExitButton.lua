local ExitButton = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)
local UIConstants = require(script.Parent.Parent.UIConstants)
local KeyboardButton = require(script.Parent.KeyboardButton)

--[[
    `closeCallbackState`: If you pass a `state`, `UIController.registerStateCloseCallback` is hooked up such that it simulates this `ExitButton` being pressed
]]
function ExitButton.new(closeCallbackState: string?)
    local button = KeyboardButton.new()

    button:SetColor(UIConstants.Colors.Buttons.CloseRed)
    button:SetIcon(Images.Icons.Close)
    button:SetPressedDebounce(UIConstants.DefaultButtonDebounce)
    button:RoundOff()
    button:Outline(UIConstants.Offsets.ButtonOutlineThickness, Color3.fromRGB(255, 255, 255))

    if closeCallbackState then
        -- story-friendly Dependency
        local Players = game:GetService("Players")
        local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
        local UIController = require(Paths.Client.UI.UIController)

        UIController.registerStateCloseCallback(closeCallbackState, function()
            button.Pressed:Fire() -- Cheeky Hack
        end)
    end

    return button
end

return ExitButton
