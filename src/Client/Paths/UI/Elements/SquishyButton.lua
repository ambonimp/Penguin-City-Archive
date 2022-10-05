local SquishyButton = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local UIConstants = require(Paths.Client.UI.UIConstants)
local Button = require(Paths.Client.UI.Elements.Button)
local Images = require(Paths.Shared.Images.Images)

function SquishyButton.new() end

return SquishyButton
