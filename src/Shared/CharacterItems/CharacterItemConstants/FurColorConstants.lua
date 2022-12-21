local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local FurColorConstants = {}
export type Item = {
    Name: string,
    Price: number,
    Icon: string,
    Color: Color3,
    ForSale: boolean,
}

local items: { [string]: Item } = {}
items["Black"] = {
    Name = "Black",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(27, 42, 53),
    ForSale = true,
}
items["Red"] = {
    Name = "Red",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(162, 0, 0),
    ForSale = true,
}
items["Purple"] = {
    Name = "Purple",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(119, 46, 247),
    ForSale = true,
}
items["Blue"] = {
    Name = "Blue",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(19, 150, 244),
    ForSale = true,
}
items["Green"] = {
    Name = "Green",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(37, 150, 52),
    ForSale = true,
}
items["Yellow"] = {
    Name = "Yellow",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(228, 228, 40),
    ForSale = true,
}
items["White"] = {
    Name = "White",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(235, 235, 235),
    ForSale = true,
}
items["Orange"] = {
    Name = "Orange",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(218, 108, 49),
    ForSale = true,
}
items["Pink"] = {
    Name = "Pink",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(255, 102, 204),
    ForSale = true,
}
items["Brown"] = {
    Name = "Brown",
    Price = 0,
    Icon = Images.Icons.Paint,
    Color = Color3.fromRGB(86, 66, 54),
    ForSale = true,
}

FurColorConstants.TabOrder = 8
FurColorConstants.TabIcon = Images.Icons.PaintBucket
FurColorConstants.SortOrder = Enum.SortOrder.Name
FurColorConstants.MaxEquippables = 1
FurColorConstants.CanUnequip = false
FurColorConstants.Items = items

return FurColorConstants
