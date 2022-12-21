local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local PantsConstants = {}
export type Item = {
    Name: string,
    Price: number,
    Icon: string,
    ForSale: boolean,
}

local items: { [string]: Item } = {}
items["Overalls"] = {
    Name = "Overalls",
    Price = 0,
    Icon = Images.Pants["Overalls"],
    ForSale = false,
}
items["White_Pants"] = {
    Name = "White_Pants",
    Price = 0,
    Icon = Images.Pants["White_Pants"],
    ForSale = true,
}
items["Blue_Jeans"] = {
    Name = "Blue_Jeans",
    Price = 0,
    Icon = nil, --"Blue_Jeans"
    ForSale = true,
}
items["Green_Pants"] = {
    Name = "Green_Pants",
    Price = 60,
    Icon = nil, --"Green_Pants"
    ForSale = false,
}
items["Bright_Red_Pants"] = {
    Name = "Bright_Red_Pants",
    Price = 60,
    Icon = nil, --"Bright_Red_Pants"
    ForSale = true,
}
items["Blue_Pants"] = {
    Name = "Blue_Pants",
    Price = 60,
    Icon = nil, --"Blue_Pants"
    ForSale = true,
}
items["Burgundy_Pants"] = {
    Name = "Burgundy_Pants",
    Price = 60,
    Icon = nil, --"Burgundy_Pants"
    ForSale = true,
}
items["Blue_Diver_Pants"] = {
    Name = "Blue_Diver_Pants",
    Price = 60,
    Icon = nil, --"Blue_Diver_Pants"
    ForSale = false,
}
items["Pink_Diver_Pants"] = {
    Name = "Pink_Diver_Pants",
    Price = 60,
    Icon = nil, --"Pink_Diver_Pants"
    ForSale = false,
}
items["Lilac_Pants"] = {
    Name = "Lilac_Pants",
    Price = 60,
    Icon = nil, --"Lilac_Pants"
    ForSale = true,
}
items["Yellow_Diver_Pants"] = {
    Name = "Yellow_Diver_Pants",
    Price = 60,
    Icon = nil, --"Yellow_Diver_Pants"
    ForSale = false,
}
items["Navy_Blue_Pants"] = {
    Name = "Navy_Blue_Pants",
    Price = 60,
    Icon = nil, --"Navy_Blue_Pants"
    ForSale = true,
}
items["Teal_Pants"] = {
    Name = "Teal_Pants",
    Price = 60,
    Icon = nil, --"Teal_Pants"
    ForSale = true,
}
items["Pink_Pants"] = {
    Name = "Pink_Pants",
    Price = 60,
    Icon = nil, --"Pink_Pants"
    ForSale = true,
}
items["Purple_Pants"] = {
    Name = "Purple_Pants",
    Price = 60,
    Icon = nil, --"Purple_Pants"
    ForSale = true,
}
items["White_Pants"] = {
    Name = "White_Pants",
    Price = 0,
    Icon = nil, --"White_Pants"
    ForSale = true,
}
items["Dark_Grey_Slacks"] = {
    Name = "Dark_Grey_Slacks",
    Price = 60,
    Icon = nil, --"Dark_Grey_Slacks"
    ForSale = true,
}
items["Student_Pants"] = {
    Name = "Student_Pants",
    Price = 60,
    Icon = nil, --"Student_Pants"
    ForSale = true,
}
items["Pink_Parisan_Skirt"] = {
    Name = "Pink_Parisan_Skirt",
    Price = 60,
    Icon = nil, --"Pink_Parisan_Skirt"
    ForSale = true,
}
items["Peach_Parisan_Skirt"] = {
    Name = "Peach_Parisan_Skirt",
    Price = 60,
    Icon = nil, --"Peach_Parisan_Skirt"
    ForSale = false,
}
items["Pink_Skirt"] = {
    Name = "Pink_Skirt",
    Price = 60,
    Icon = nil, --"Pink_Skirt"
    ForSale = true,
}
items["Yellow_Skirt"] = {
    Name = "Yellow_Skirt",
    Price = 60,
    Icon = nil, --"Yellow_Skirt"
    ForSale = true,
}
items["Fluffy_Pink_Skirt"] = {
    Name = "Fluffy_Pink_Skirt",
    Price = 60,
    Icon = nil, --"Fluffy_Pink_Skirt"
    ForSale = true,
}
items["Bright_Green_Pants"] = {
    Name = "Bright_Green_Pants",
    Price = 60,
    Icon = nil, --"Bright_Green_Pants"
    ForSale = true,
}

PantsConstants.AssetsPath = "Pants"
PantsConstants.TabOrder = 2
PantsConstants.TabIcon = Images.Icons.Pants
PantsConstants.SortOrder = Enum.SortOrder.LayoutOrder
PantsConstants.MaxEquippables = 1
PantsConstants.CanUnequip = true
PantsConstants.Items = items

return PantsConstants
