local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local FurColorConstants = {}
export type Item = {
    Price: number,
    Icon: string,
    Color: Color3,
}

FurColorConstants.InventoryPath = "FurColors"
FurColorConstants.TabOrder = 3
FurColorConstants.TabIcon = Images.Icons.PaintBucket
FurColorConstants.SortOrder = Enum.SortOrder.Name
FurColorConstants.MaxEquippables = 1
FurColorConstants.CanUnequip = false
FurColorConstants.Items = {
    ["Black"] = {
        Price = 0,
        Icon = Images.Icons.Paint,
        Color = Color3.fromRGB(27, 42, 53),
    } :: Item,
    ["Red"] = {
        Price = 0,
        Icon = Images.Icons.Paint,
        Color = Color3.fromRGB(255, 0, 0),
    } :: Item,
    ["Blue"] = {
        Price = 0,
        Icon = Images.Icons.Paint,
        Color = Color3.fromRGB(0, 0, 255),
    } :: Item,
    ["Green"] = {
        Price = 0,
        Icon = Images.Icons.Paint,
        Color = Color3.fromRGB(0, 255, 0),
    } :: Item,
    ["Yellow"] = {
        Price = 0,
        Icon = Images.Icons.Paint,
        Color = Color3.fromRGB(255, 255, 0),
    } :: Item,
}

return FurColorConstants
