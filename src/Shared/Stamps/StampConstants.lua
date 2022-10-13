local StampConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

StampConstants.TitleIconResolutions = {
    [Images.StampBook.Titles.Pizza] = Vector2.new(523, 90),
} :: { [string]: Vector2 }

return StampConstants
