local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local FurnitureConstants = {}

export type Object = {
    Name: string,
    Price: number,
    Icon: string,
    Sort: "String",
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
FurnitureConstants.Objects = {
    ["Chair"] = {
        Name = "Chair",
        Type = FurnitureConstants.Types.Seating,
        Price = 0,
        Icon = "",
        Interactable = true,
        DefaultColor = Color3.fromRGB(124, 92, 70),
    } :: Object,
    ["Couch"] = {
        Name = "Couch",
        Type = FurnitureConstants.Types.Seating,
        Price = 0,
        Icon = "",
        Interactable = true,
        DefaultColor = Color3.fromRGB(150, 85, 85),
    } :: Object,
    ["Plant"] = {
        Name = "Plant",
        Type = FurnitureConstants.Types.Decoration,
        Price = 0,
        Icon = "",
        Interactable = false,
        DefaultColor = Color3.fromRGB(248, 248, 248),
    } :: Object,
    ["Table"] = {
        Name = "Table",
        Type = FurnitureConstants.Types.Seating,
        Price = 0,
        Icon = "",
        Interactable = false,
        DefaultColor = Color3.fromRGB(124, 92, 70),
    } :: Object,
    ["Table_Lamp"] = {
        Name = "Table_Lamp",
        Type = FurnitureConstants.Types.Decoration,
        Price = 0,
        Icon = "",
        Interactable = true,
        DefaultColor = Color3.fromRGB(255, 240, 213),
    } :: Object,
}

return FurnitureConstants
