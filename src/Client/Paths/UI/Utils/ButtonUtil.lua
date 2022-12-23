local ButtonUtil = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local KeyboardButton = require(Paths.Client.UI.Elements.KeyboardButton)
local UIConstants = require(Paths.Client.UI.UIConstants)
local Images = require(Paths.Shared.Images.Images)

function ButtonUtil.paintIgloo(keyboardButton: KeyboardButton.KeyboardButton)
    keyboardButton:SetColor(UIConstants.Colors.Buttons.IglooPink)
    keyboardButton:SetIcon(Images.Icons.Igloo)
end

function ButtonUtil.paintEdit(keyboardButton: KeyboardButton.KeyboardButton)
    keyboardButton:SetColor(UIConstants.Colors.Buttons.EditOrange)
    keyboardButton:SetIcon(Images.Icons.Wrench)
end

function ButtonUtil.paintStamps(keyboardButton: KeyboardButton.KeyboardButton)
    keyboardButton:SetColor(UIConstants.Colors.Buttons.StampBeige)
    keyboardButton:SetIcon(Images.ButtonIcons.StampBook)
end

return ButtonUtil
