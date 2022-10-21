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
}

local objects: { [string]: Object } = {}
objects["Chair"] = {
    Name = "Chair",
    Type = FurnitureConstants.Types.Seating,
    Price = 0,
    Icon = "",
    Interactable = true,
    DefaultColor = Color3.fromRGB(124, 92, 70),
}
objects["Couch"] = {
    Name = "Couch",
    Type = FurnitureConstants.Types.Seating,
    Price = 0,
    Icon = "",
    Interactable = true,
    DefaultColor = Color3.fromRGB(150, 85, 85),
}
objects["Plant"] = {
    Name = "Plant",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
    DefaultColor = Color3.fromRGB(248, 248, 248),
}
objects["Table"] = {
    Name = "Table",
    Type = FurnitureConstants.Types.Seating,
    Price = 0,
    Icon = "",
    Interactable = false,
    DefaultColor = Color3.fromRGB(124, 92, 70),
}
objects["Table_Lamp"] = {
    Name = "Table_Lamp",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = true,
    DefaultColor = Color3.fromRGB(255, 240, 213),
}

FurnitureConstants.Objects = objects

return FurnitureConstants
