local FurnitureConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

export type Object = {
    Name: string,
    Type: string,
    Price: number,
    Icon: string,
    Interactable: boolean,
    Tags: { string },
}

local Tags = {
    Kitchen = "Kitchen",
    DiningRoom = "Dining Room",
    Bathroom = "Bathroom",
    BedRoom = "Bed Room",
    LivingRoom = "Living Room",
    Couches = "Couches",
    Chairs = "Chairs",
    Beds = "Beds",
    Shelves = "Shelves",
    Cabinet = "Cabinet",
    Decorations = "Decorations",
    Entertainment = "Entertainment",
    Tables = "Tables",
    Desks = "Desks",
    Lights = "Lights",
    Wall = "Wall",
}

FurnitureConstants.MainTabs = {
    Seats = {
        Icon = Images.Icons.Furniture,
        SubTabs = { Tags.Couches, Tags.Chairs, Tags.Desks, Tags.Beds },
    },
    Furniture = {
        Icon = Images.Icons.Furniture,
        SubTabs = { Tags.LivingRoom, Tags.BedRoom, Tags.DiningRoom, Tags.Bathroom, Tags.Kitchen, Tags.Tables, Tags.Desks },
    },
    Decoration = {
        Icon = Images.Icons.Furniture,
        SubTabs = { Tags.Lights, Tags.Shelves, Tags.Tables, Tags.Desks, Tags.Cabinet, Tags.Wall, Tags.Decorations, Tags.Entertainment },
    },
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
FurnitureConstants.Tags = Tags
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
    Price = 20,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Couches, Tags.LivingRoom },
}
objects["BARREL"] = {
    Name = "Barrel",
    Type = FurnitureConstants.Types.Decoration,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations },
}
objects["VINYL_03"] = {
    Name = "Vinyl",
    Type = FurnitureConstants.Types.Decoration,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations, Tags.Entertainment, Tags.Wall },
}
objects["VINYL_02"] = {
    Name = "Vinyl",
    Type = FurnitureConstants.Types.Decoration,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations, Tags.Entertainment, Tags.Wall },
}
objects["VINYL_01"] = {
    Name = "Vinyl",
    Type = FurnitureConstants.Types.Decoration,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations, Tags.Entertainment, Tags.Wall },
}
objects["Table_Lamp_01"] = {
    Name = "Table Lamp",
    Type = FurnitureConstants.Types.Light,
    Price = 20,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Tables, Tags.Lights },
}
objects["Table"] = {
    Name = "Table",
    Type = FurnitureConstants.Types.Table,
    Price = 25,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Tables, Tags.LivingRoom },
}
objects["TV"] = {
    Name = "TV",
    Type = FurnitureConstants.Types.Decoration,
    Price = 30,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Entertainment, Tags.Decorations },
}
objects["TABLE_LAMP_02"] = {
    Name = "Table Lamp",
    Type = FurnitureConstants.Types.Light,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Tables, Tags.Lights },
}
objects["Studio_Light"] = {
    Name = "Studio Light",
    Type = FurnitureConstants.Types.Light,
    Price = 20,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations, Tags.Lights },
}
objects["Stove"] = {
    Name = "Stove",
    Type = FurnitureConstants.Types.Decoration,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Kitchen },
}
objects["Stool_3"] = {
    Name = "Stool",
    Type = FurnitureConstants.Types.Seat,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Chairs },
}
objects["Stool_2"] = {
    Name = "Stool",
    Type = FurnitureConstants.Types.Seat,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Chairs },
}
objects["Stool_1"] = {
    Name = "Stool",
    Type = FurnitureConstants.Types.Seat,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Chairs },
}
objects["Speakers"] = {
    Name = "Speakers",
    Type = FurnitureConstants.Types.Decoration,
    Price = 20,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations, Tags.Entertainment },
}
objects["Sink"] = {
    Name = "Sink",
    Type = FurnitureConstants.Types.Decoration,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Bathroom, Tags.Kitchen },
}
objects["SHELF_1"] = {
    Name = "Shelf",
    Type = FurnitureConstants.Types.Shelf,
    Price = 25,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Shelves, Tags.LivingRoom, Tags.BedRoom },
}
objects["STONE_LANTERN"] = {
    Name = "Stone Lantern",
    Type = FurnitureConstants.Types.Light,
    Price = 30,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations, Tags.Lights },
}
objects["SNOWMAN_2"] = {
    Name = "Snowman",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 50,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations },
}
objects["SNOWMAN_1"] = {
    Name = "Snowman",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 50,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations },
}
objects["SHELF_2"] = {
    Name = "Shelf",
    Type = FurnitureConstants.Types.Shelf,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Shelves, Tags.LivingRoom, Tags.BedRoom },
}
objects["Recliner"] = {
    Name = "Recliner",
    Type = FurnitureConstants.Types.Seat,
    Price = 20,
    Icon = "",
    Interactable = false,
    Tags = { Tags.LivingRoom, Tags.BedRoom, Tags.Chairs },
}
objects["Pool_Table"] = {
    Name = "Billiards",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 30,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations, Tags.LivingRoom, Tags.Entertainment },
}
objects["Pointed_Tree"] = {
    Name = "Tree",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 35,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations, Tags.LivingRoom, Tags.Entertainment },
}
objects["Pizza_Oven"] = {
    Name = "Pizza Oven",
    Type = FurnitureConstants.Types.Decoration,
    Price = 25,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations, Tags.Kitchen, Tags.Entertainment },
}
objects["Pet_House"] = {
    Name = "Pet House",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 10,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations, Tags.BedRoom, Tags.Entertainment },
}
objects["Pet_Bowl_2"] = {
    Name = "Pet Bowl",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 10,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations, Tags.BedRoom, Tags.Entertainment },
}
objects["Pet_Bowl_1"] = {
    Name = "Pet Bowl",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 10,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations, Tags.BedRoom, Tags.Entertainment },
}
objects["Pet_Bed"] = {
    Name = "Pet Bed",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 10,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations, Tags.BedRoom, Tags.Entertainment },
}
objects["PLANT"] = {
    Name = "Plant",
    Type = FurnitureConstants.Types.Decoration,
    Price = 10,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations, Tags.LivingRoom, Tags.BedRoom },
}
objects["NIGHTSTAND"] = {
    Name = "Nightstand",
    Type = FurnitureConstants.Types.Decoration,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.BedRoom, Tags.Cabinet },
}
objects["Mop_Bucket"] = {
    Name = "Mop & Bucket",
    Type = FurnitureConstants.Types.Miscellaneous,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Bathroom, Tags.Kitchen, Tags.Decorations },
}
objects["COMPUTER_TABLE"] = {
    Name = "Computer Table",
    Type = FurnitureConstants.Types.Decoration,
    Price = 40,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Entertainment, Tags.LivingRoom, Tags.BedRoom, Tags.Tables },
}
objects["LAVA_LAMP_1"] = {
    Name = "Lava Lamp",
    Type = FurnitureConstants.Types.Light,
    Price = 25,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations, Tags.Lights },
}
objects["LARGE_CRATE"] = {
    Name = "Crate",
    Type = FurnitureConstants.Types.Decoration,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations },
}
objects["Hockey_Table"] = {
    Name = "Air Hockey",
    Type = FurnitureConstants.Types.Decoration,
    Price = 35,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Entertainment, Tags.LivingRoom, Tags.Tables },
}
objects["High End Sofa"] = {
    Name = "Sofa",
    Type = FurnitureConstants.Types.Seat,
    Price = 50,
    Icon = "",
    Interactable = false,
    Tags = { Tags.LivingRoom, Tags.Couches },
}
objects["High End Chair"] = {
    Name = "Chair",
    Type = FurnitureConstants.Types.Seat,
    Price = 50,
    Icon = "",
    Interactable = false,
    Tags = { Tags.LivingRoom, Tags.Chairs },
}
objects["Glass_Table_3"] = {
    Name = "Glass Table",
    Type = FurnitureConstants.Types.Table,
    Price = 25,
    Icon = "",
    Interactable = false,
    Tags = { Tags.LivingRoom, Tags.Tables, Tags.DiningRoom },
}
objects["Glass_Table_2"] = {
    Name = "Glass Table",
    Type = FurnitureConstants.Types.Table,
    Price = 25,
    Icon = "",
    Interactable = false,
    Tags = { Tags.LivingRoom, Tags.Tables, Tags.DiningRoom },
}
objects["Glass_Table_1"] = {
    Name = "Glass Table",
    Type = FurnitureConstants.Types.Table,
    Price = 25,
    Icon = "",
    Interactable = false,
    Tags = { Tags.LivingRoom, Tags.Tables, Tags.DiningRoom },
}
objects["Gaming_Chair"] = {
    Name = "Gaming Chair",
    Type = FurnitureConstants.Types.Seat,
    Price = 30,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Entertainment, Tags.LivingRoom, Tags.Chairs },
}
objects["Floor_Lamp_2"] = {
    Name = "Floor Lamp",
    Type = FurnitureConstants.Types.Light,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Lights, Tags.Decorations },
}
objects["Floor_Lamp_01"] = {
    Name = "Floor Lamp",
    Type = FurnitureConstants.Types.Light,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Lights, Tags.Decorations },
}
objects["Fish_Bowl"] = {
    Name = "Fish Bowl",
    Type = FurnitureConstants.Types.Decoration,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations },
}
objects["Fire_Place_1"] = {
    Name = "Fireplace",
    Type = FurnitureConstants.Types.Light,
    Price = 20,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Lights, Tags.Decorations },
}
objects["Fire_Place_2"] = {
    Name = "Fireplace",
    Type = FurnitureConstants.Types.Light,
    Price = 20,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Lights, Tags.Decorations },
}
objects["FRIDGE"] = {
    Name = "Fridge",
    Type = FurnitureConstants.Types.Decoration,
    Price = 25,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Kitchen },
}
objects["Entertainment_Center"] = {
    Name = "TV & Shelf",
    Type = FurnitureConstants.Types.Decoration,
    Price = 55,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Entertainment },
}
objects["Dresser_1"] = {
    Name = "Dresser",
    Type = FurnitureConstants.Types.Decoration,
    Price = 20,
    Icon = "",
    Interactable = false,
    Tags = { Tags.BedRoom, Tags.Cabinet },
}
objects["Dining_Table_2"] = {
    Name = "Table",
    Type = FurnitureConstants.Types.Table,
    Price = 20,
    Icon = "",
    Interactable = false,
    Tags = { Tags.DiningRoom, Tags.Tables },
}
objects["Dining_Table_1"] = {
    Name = "Table",
    Type = FurnitureConstants.Types.Table,
    Price = 20,
    Icon = "",
    Interactable = false,
    Tags = { Tags.DiningRoom, Tags.Tables },
}
objects["Cube_Shelf"] = {
    Name = "Shelf",
    Type = FurnitureConstants.Types.Shelf,
    Price = 30,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Shelves, Tags.Decorations },
}
objects["Couch_03"] = {
    Name = "Couch",
    Type = FurnitureConstants.Types.Seat,
    Price = 20,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Couches, Tags.LivingRoom },
}
objects["Couch_02"] = {
    Name = "Couch",
    Type = FurnitureConstants.Types.Seat,
    Price = 20,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Couches, Tags.LivingRoom },
}
objects["BOOKSHELF_02"] = {
    Name = "Bookshelf",
    Type = FurnitureConstants.Types.Shelf,
    Price = 20,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Shelves, Tags.Decorations },
}
objects["BOOKSHELF_03"] = {
    Name = "Bookshelf",
    Type = FurnitureConstants.Types.Shelf,
    Price = 20,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Shelves, Tags.Decorations },
}
objects["Balloons"] = {
    Name = "Balloons",
    Type = FurnitureConstants.Types.Decoration,
    Price = 10,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations },
}
objects["Basketball_Net"] = {
    Name = "Basketball Net",
    Type = FurnitureConstants.Types.Decoration,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations, Tags.Wall },
}
objects["Bean_Bag"] = {
    Name = "Bean Bag",
    Type = FurnitureConstants.Types.Seat,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Chairs, Tags.Decorations },
}
objects["Bed"] = {
    Name = "Bed",
    Type = FurnitureConstants.Types.Seat,
    Price = 25,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Chairs, Tags.Beds },
}
objects["Bookshelf"] = {
    Name = "Bookshelf",
    Type = FurnitureConstants.Types.Decoration,
    Price = 20,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Shelves, Tags.Decorations },
}
objects["CIRCULAR_TABLE_1"] = {
    Name = "Table",
    Type = FurnitureConstants.Types.Table,
    Price = 25,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Tables, Tags.LivingRoom, Tags.DiningRoom },
}
objects["CIRCULAR_TABLE_2"] = {
    Name = "Table",
    Type = FurnitureConstants.Types.Table,
    Price = 25,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Tables, Tags.LivingRoom, Tags.DiningRoom },
}
objects["CLOCK"] = {
    Name = "Clock",
    Type = FurnitureConstants.Types.Decoration,
    Price = 10,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations, Tags.Wall },
}
objects["CRATE_1"] = {
    Name = "Crate",
    Type = FurnitureConstants.Types.Decoration,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Decorations },
}
objects["Camping_Chair"] = {
    Name = "Chair",
    Type = FurnitureConstants.Types.Seat,
    Price = 15,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Chair },
}
objects["Canopy_Bed"] = {
    Name = "Bed",
    Type = FurnitureConstants.Types.Seat,
    Price = 25,
    Icon = "",
    Interactable = false,
    Tags = { Tags.BedRoom, Tags.Beds },
}
objects["Carpet"] = {
    Name = "Carpet",
    Type = FurnitureConstants.Types.Decoration,
    Price = 10,
    Icon = "",
    Interactable = false,
    Tags = { Tags.LivingRoom, Tags.BedRoom, Tags.Decorations },
}
objects["Chair_1"] = {
    Name = "Chair",
    Type = FurnitureConstants.Types.Seat,
    Price = 10,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Chair },
}
objects["Chair_2"] = {
    Name = "Chair",
    Type = FurnitureConstants.Types.Seat,
    Price = 10,
    Icon = "",
    Interactable = false,
    Tags = { Tags.Chair },
}
objects["CoffeeTable"] = {
    Name = "Table",
    Type = FurnitureConstants.Types.Table,
    Price = 25,
    Icon = "",
    Interactable = false,
    Tags = { Tags.DiningRoom, Tags.Tables },
}
FurnitureConstants.Objects = objects

FurnitureConstants.AssetsPath = "Furniture"

local objectsWithTagExist = {}

function FurnitureConstants.GetObjectsFromTag(tag)
    if objectsWithTagExist[tag] then
        return objectsWithTagExist[tag]
    end
    local objectsWithTag = {} :: { [string]: Object }

    for name, object in objects do
        if table.find(object.Tags, tag) then
            objectsWithTag[name] = object
        end
    end
    objectsWithTagExist[tag] = objectsWithTag
    return objectsWithTag
end

return FurnitureConstants
