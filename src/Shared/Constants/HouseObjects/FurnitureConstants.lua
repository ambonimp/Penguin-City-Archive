local FurnitureConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

export type Object = {
    Name: string,
    Type: string,
    Price: number,
    Icon: string,
    Interactable: boolean,
    DefaultColor: Color3,
}

FurnitureConstants.TabOrder = 1
FurnitureConstants.TabIcon = Images.Icons.Furniture
FurnitureConstants.Types = {
    Seat = "Seats",
    Table = "Tables",
    Decoration = "Decorations",
    Miscellaneous = "Miscellaneous",
    Shelf = "Shelfs",
    Light = "Lighting",
}
FurnitureConstants.Colors = {
    Orange = Color3.fromRGB(165, 55, 71),
    DullPink = Color3.fromRGB(171, 63, 115),
    Blue = Color3.fromRGB(16, 42, 220),
    Yellow = Color3.fromRGB(226, 155, 64),
    Green = Color3.fromRGB(58, 125, 21),
    Teal = Color3.fromRGB(18, 238, 212),
    DullBrown = Color3.fromRGB(99, 95, 98),
}

local objects: { [string]: Object } = {}
objects["Bean_Bag"] = {
    Name = "Bean Bag",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
    DefaultColor = FurnitureConstants.Colors.Orange,
}
objects["Bed"] = {
    Name = "Bed",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
    DefaultColor = FurnitureConstants.Colors.DullPink,
}
objects["Bookshelf"] = {
    Name = "BookShelf",
    Type = FurnitureConstants.Types.Shelf,
    Price = 0,
    Icon = "",
    Interactable = true,
    DefaultColor = FurnitureConstants.Colors.Blue,
}
objects["Camping_Chair"] = {
    Name = "Camping Chair",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = true,
    DefaultColor = FurnitureConstants.Colors.Blue,
}
objects["Chair"] = {
    Name = "Chair",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = true,
    DefaultColor = FurnitureConstants.Colors.Orange,
}
objects["Couch_01"] = {
    Name = "Couch",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = true,
    DefaultColor = FurnitureConstants.Colors.Green,
}
objects["Couch_02"] = {
    Name = "Couch",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = true,
    DefaultColor = FurnitureConstants.Colors.DullBrown,
}
objects["Couch_03"] = {
    Name = "Couch",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = true,
    DefaultColor = FurnitureConstants.Colors.Blue,
}
objects["Floor_Lamp_01"] = {
    Name = "Floor Lamp",
    Type = FurnitureConstants.Types.Light,
    Price = 0,
    Icon = "",
    Interactable = true,
    DefaultColor = FurnitureConstants.Colors.Orange,
}
objects["Floor_Lamp_01"] = {
    Name = "Floor Lamp",
    Type = FurnitureConstants.Types.Light,
    Price = 0,
    Icon = "",
    Interactable = true,
    DefaultColor = FurnitureConstants.Colors.Green,
}
objects["Fridge"] = {
    Name = "Fridge",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 0,
    Icon = "",
    Interactable = true,
    DefaultColor = FurnitureConstants.Colors.Teal,
}
objects["Fireplace"] = {
    Name = "FirePlace",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 0,
    Icon = "",
    Interactable = true,
    DefaultColor = FurnitureConstants.Colors.DullBrown,
}
objects["Sink"] = {
    Name = "Sink",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 0,
    Icon = "",
    Interactable = true,
    DefaultColor = FurnitureConstants.Colors.Green,
}
objects["Stove"] = {
    Name = "Stove",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 0,
    Icon = "",
    Interactable = true,
    DefaultColor = FurnitureConstants.Colors.Orange,
}
objects["Table"] = {
    Name = "Table",
    Type = FurnitureConstants.Types.Table,
    Price = 0,
    Icon = "",
    Interactable = true,
    DefaultColor = FurnitureConstants.Colors.Yellow,
}
objects["Table_Lamp_01"] = {
    Name = "Table",
    Type = FurnitureConstants.Types.Light,
    Price = 0,
    Icon = "",
    Interactable = true,
    DefaultColor = FurnitureConstants.Colors.Orange,
}
FurnitureConstants.Objects = objects

return FurnitureConstants
