local FurnitureConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

export type Object = {
    Name: string,
    Type: string,
    Price: number,
    Icon: string,
    Interactable: boolean,
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
    Red = { ImageColor = Color3.fromRGB(199, 10, 42), Price = 0 },
    Purple = { ImageColor = Color3.fromRGB(123, 10, 199), Price = 0 },
    Blue = { ImageColor = Color3.fromRGB(0, 153, 255), Price = 0 },
    Yellow = { ImageColor = Color3.fromRGB(226, 188, 64), Price = 0 },
    Orange = { ImageColor = Color3.fromRGB(211, 96, 30), Price = 0 },
    Brown = { ImageColor = Color3.fromRGB(128, 65, 6), Price = 0 },
    Green = { ImageColor = Color3.fromRGB(58, 125, 21), Price = 0 },
    Black = { ImageColor = Color3.fromRGB(20, 20, 20), Price = 0 },
    White = { ImageColor = Color3.fromRGB(231, 231, 231), Price = 0 },
    Teal = { ImageColor = Color3.fromRGB(18, 238, 212), Price = 15 },
    LimeGreen = { ImageColor = Color3.fromRGB(73, 206, 2), Price = 15 },
    Gray = { ImageColor = Color3.fromRGB(127, 127, 127), Price = 15 },
    Pink = { ImageColor = Color3.fromRGB(255, 119, 226), Price = 15 },
    HotRed = { ImageColor = Color3.fromRGB(255, 0, 0), Price = 15 },
    DarkBlue = { ImageColor = Color3.fromRGB(16, 42, 220), Price = 15 },
}

local objects: { [string]: Object } = {}
objects["Couch_01"] = {
    Name = "Couch",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["BARREL"] = {
    Name = "Barrel",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["VINYL_03"] = {
    Name = "Vinyl",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["VINYL_02"] = {
    Name = "Vinyl",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["VINYL_01"] = {
    Name = "Vinyl",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Table_Lamp_01"] = {
    Name = "Table Lamp",
    Type = FurnitureConstants.Types.Light,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Table"] = {
    Name = "Table",
    Type = FurnitureConstants.Types.Table,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["TV"] = {
    Name = "TV",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["TABLE_LAMP_02"] = {
    Name = "Table Lamp",
    Type = FurnitureConstants.Types.Light,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Studio_Light"] = {
    Name = "Studio Light",
    Type = FurnitureConstants.Types.Light,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Stove"] = {
    Name = "Stove",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Stool_3"] = {
    Name = "Stool",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Stool_2"] = {
    Name = "Stool",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Stool_1"] = {
    Name = "Stool",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Speakers"] = {
    Name = "Speakers",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Sink"] = {
    Name = "Sink",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["SHELF_1"] = {
    Name = "Shelf",
    Type = FurnitureConstants.Types.Shelf,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["STONE_LANTERN"] = {
    Name = "Stone Lantern",
    Type = FurnitureConstants.Types.Light,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["SNOWMAN_2"] = {
    Name = "Snowman",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["SNOWMAN_1"] = {
    Name = "Snowman",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["SHELF_2"] = {
    Name = "Shelf",
    Type = FurnitureConstants.Types.Shelf,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Recliner"] = {
    Name = "Recliner",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Pool_Table"] = {
    Name = "Billiards",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Pointed_Tree"] = {
    Name = "Tree",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Pizza_Oven"] = {
    Name = "Pizza Oven",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Pet_House"] = {
    Name = "Pet House",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Pet_Bowl_2"] = {
    Name = "Pet Bowl",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Pet_Bowl_1"] = {
    Name = "Pet Bowl",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Pet_Bed"] = {
    Name = "Pet Bed",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["PLANT"] = {
    Name = "Plant",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["NIGHTSTAND"] = {
    Name = "Nightstand",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Mop_Bucket"] = {
    Name = "Mop & Bucket",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["COMPUTER_TABLE"] = {
    Name = "Computer Table",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["LAVA_LAMP_1"] = {
    Name = "Lava Lamp",
    Type = FurnitureConstants.Types.Light,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["LARGE_CRATE"] = {
    Name = "Crate",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Hockey_Table"] = {
    Name = "Air Hockey",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["High End Sofa"] = {
    Name = "Sofa",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["High End Chair"] = {
    Name = "Chair",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Glass_Table_3"] = {
    Name = "Glass Table",
    Type = FurnitureConstants.Types.Table,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Glass_Table_2"] = {
    Name = "Glass Table",
    Type = FurnitureConstants.Types.Table,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Glass_Table_1"] = {
    Name = "Glass Table",
    Type = FurnitureConstants.Types.Table,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Gaming_Chair"] = {
    Name = "Gaming Chair",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Floor_Lamp_2"] = {
    Name = "Floor Lamp",
    Type = FurnitureConstants.Types.Light,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Floor_Lamp_01"] = {
    Name = "Floor Lamp",
    Type = FurnitureConstants.Types.Light,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Fish_Bowl"] = {
    Name = "Fish Bowl",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Fire_Place_1"] = {
    Name = "Fireplace",
    Type = FurnitureConstants.Types.Light,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Fire_Place_2"] = {
    Name = "Fireplace",
    Type = FurnitureConstants.Types.Light,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["FRIDGE"] = {
    Name = "Fridge",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Entertainment_Center"] = {
    Name = "TV & Shelf",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Dresser_1"] = {
    Name = "Dresser",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Dining_Table_2"] = {
    Name = "Table",
    Type = FurnitureConstants.Types.Table,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Dining_Table_1"] = {
    Name = "Table",
    Type = FurnitureConstants.Types.Table,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Cube_Shelf"] = {
    Name = "Shelf",
    Type = FurnitureConstants.Types.Shelf,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Couch_03"] = {
    Name = "Couch",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Couch_02"] = {
    Name = "Couch",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["BOOKSHELF_02"] = {
    Name = "Bookshelf",
    Type = FurnitureConstants.Types.Shelf,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["BOOKSHELF_03"] = {
    Name = "Bookshelf",
    Type = FurnitureConstants.Types.Shelf,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Balloons"] = {
    Name = "Balloons",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Basketball_Net"] = {
    Name = "Basketball Net",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Bean_Bag"] = {
    Name = "Bean Bag",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Bed"] = {
    Name = "Bed",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Bookshelf"] = {
    Name = "Bookshelf",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["CIRCULAR_TABLE_1"] = {
    Name = "Table",
    Type = FurnitureConstants.Types.Table,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["CIRCULAR_TABLE_2"] = {
    Name = "Table",
    Type = FurnitureConstants.Types.Table,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["CLOCK"] = {
    Name = "Clock",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["CRATE_1"] = {
    Name = "Crate",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Camping_Chair"] = {
    Name = "Chair",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Canopy_Bed"] = {
    Name = "Bed",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Carpet"] = {
    Name = "Carpet",
    Type = FurnitureConstants.Types.Decoration,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Chair_1"] = {
    Name = "Chair",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["Chair_2"] = {
    Name = "Chair",
    Type = FurnitureConstants.Types.Seat,
    Price = 0,
    Icon = "",
    Interactable = false,
}
objects["CoffeeTable"] = {
    Name = "Table",
    Type = FurnitureConstants.Types.Table,
    Price = 0,
    Icon = "",
    Interactable = false,
}
FurnitureConstants.Objects = objects

FurnitureConstants.AssetsPath = "Furniture"

return FurnitureConstants
