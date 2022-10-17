local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local FurColorConstants = {}
export type Item = {
    Name: string,
    Price: number,
    Icon: string,
    Color: Color3,
}

local items: { [string]: Item } = {}
items["Black"] = {
    Name = "Black",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(27, 42, 53),
}
items["Red"] = {
    Name = "Red",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(255, 0, 0),
}
items["Blue"] = {
    Name = "Blue",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(0, 0, 255),
}
items["Green"] = {
    Name = "Green",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(0, 255, 0),
}
items["Yellow"] = {
    Name = "Yellow",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(255, 255, 0),
}

FurColorConstants.InventoryPath = "FurColors"
FurColorConstants.TabOrder = 8
FurColorConstants.TabIcon = Images.Icons.PaintBucket
FurColorConstants.SortOrder = Enum.SortOrder.Name
FurColorConstants.MaxEquippables = 1
FurColorConstants.CanUnequip = false
FurColorConstants.Items = items

return FurColorConstants
