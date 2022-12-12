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
    Color = Color3.fromRGB(197, 41, 41),
}
items["Blue"] = {
    Name = "Blue",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(44, 44, 185),
}
items["Green"] = {
    Name = "Green",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(51, 207, 51),
}
items["Yellow"] = {
    Name = "Yellow",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(226, 226, 56),
}
items["White"] = {
    Name = "White",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(235, 235, 235),
}
items["Orange"] = {
    Name = "Orange",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(248, 182, 40),
}
items["Pink"] = {
    Name = "Pink",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(200, 34, 233),
}

FurColorConstants.TabOrder = 8
FurColorConstants.TabIcon = Images.Icons.PaintBucket
FurColorConstants.SortOrder = Enum.SortOrder.Name
FurColorConstants.MaxEquippables = 1
FurColorConstants.CanUnequip = false
FurColorConstants.Items = items

return FurColorConstants
