local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Images = require(Paths.Shared.Images.Images)

local CharacterEditorConstants = {}

CharacterEditorConstants.BodyType = {
    LayoutOrder = 1,
    Icon = Images.Icons.Face,
}

return CharacterEditorConstants
