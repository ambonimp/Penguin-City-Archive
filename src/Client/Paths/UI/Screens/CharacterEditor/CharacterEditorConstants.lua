local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Images = require(Paths.Shared.Images.Images)

local CharacterEditorConstants = {}

export type Category = {
    LayoutOrder: number,
    Icon: string,
    SortOrder: Enum.SortOrder,
}

CharacterEditorConstants.BodyType = {
    LayoutOrder = 1,
    Icon = Images.Icons.Face,
    SortOrder = Enum.SortOrder.LayoutOrder,
} :: Category

CharacterEditorConstants.FurColor = {
    LayoutOrder = 2,
    Icon = Images.Icons.PaintBucket,
    SortOrder = Enum.SortOrder.Name,
} :: Category

return CharacterEditorConstants
