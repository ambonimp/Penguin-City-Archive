local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local ShoesConstants = {}
export type Item = {
    Name: string,
    Price: number,
    Icon: string,
    ForSale: boolean,
}

local items: { [string]: Item } = {}
items["Black_Sneakers"] = {
    Name = "Black_Sneakers",
    Price = 50,
    Icon = nil, --"Black_Sneakers"
    ForSale = true,
}
items["Bright_Red_Shoes"] = {
    Name = "Bright_Red_Shoes",
    Price = 50,
    Icon = nil, --"Bright_Red_Shoes"
    ForSale = true,
}
items["Blue_Sneakers"] = {
    Name = "Blue_Sneakers",
    Price = 50,
    Icon = nil, --"Blue_Sneakers"
    ForSale = true,
}
items["Dark_Red_Sneakers"] = {
    Name = "Dark_Red_Sneakers",
    Price = 0,
    Icon = nil, --"Dark_Red_Sneakers"
    ForSale = true,
}
items["Green_Sneakers"] = {
    Name = "Green_Sneakers",
    Price = 0,
    Icon = nil, --"Green_Sneakers"
    ForSale = true,
}
items["Cyan_Sneakers"] = {
    Name = "Cyan_Sneakers",
    Price = 50,
    Icon = nil, --"Cyan_Sneakers"
    ForSale = true,
}
items["Glowing_Green_Sneakers"] = {
    Name = "Glowing_Green_Sneakers",
    Price = 150,
    Icon = nil, --"Glowing_Green_Sneakers"
    ForSale = true,
}
items["Glowing_Red_Sneakers"] = {
    Name = "Glowing_Red_Sneakers",
    Price = 150,
    Icon = nil, --"Glowing_Red_Sneakers"
    ForSale = true,
}
items["Blue_Slippers"] = {
    Name = "Blue_Slippers",
    Price = 50,
    Icon = nil, --"Blue_Slippers"
    ForSale = true,
}
items["Green_Slippers"] = {
    Name = "Green_Slippers",
    Price = 50,
    Icon = nil, --"Green_Slippers"
    ForSale = true,
}
items["All_White_Sneakers"] = {
    Name = "All_White_Sneakers",
    Price = 50,
    Icon = nil, --"All_White_Sneakers"
    ForSale = true,
}
items["Blue_Slippers"] = {
    Name = "Blue_Slippers",
    Price = 50,
    Icon = nil, --"Blue_Slippers"
    ForSale = true,
}
items["All_White_Slippers"] = {
    Name = "All_White_Slippers",
    Price = 50,
    Icon = nil, --"All_White_Slippers"
    ForSale = true,
}
items["Peach_Slippers"] = {
    Name = "Peach_Slippers",
    Price = 50,
    Icon = nil, --"Peach_Slippers"
    ForSale = true,
}
items["Pink_Slippers"] = {
    Name = "Pink_Slippers",
    Price = 50,
    Icon = nil, --"Pink_Slippers"
    ForSale = true,
}
items["Red_Slippers"] = {
    Name = "Red_Slippers",
    Price = 50,
    Icon = nil, --"Red_Slippers"
    ForSale = true,
}
items["Purple_Glowing_Sneakers"] = {
    Name = "Purple_Glowing_Sneakers",
    Price = 150,
    Icon = nil, --"Purple_Glowing_Sneakers"
    ForSale = true,
}
items["Pink_Sneakers"] = {
    Name = "Pink_Sneakers",
    Price = 50,
    Icon = nil, --"Pink_Sneakers"
    ForSale = true,
}
items["Peach_Sneakers"] = {
    Name = "Peach_Sneakers",
    Price = 50,
    Icon = nil, --"Peach_Sneakers"
    ForSale = false,
}
items["White_Green_Sneakers"] = {
    Name = "White_Green_Sneakers",
    Price = 50,
    Icon = nil, --"White_Green_Sneakers"
    ForSale = true,
}
items["Purple_Classy_Sneakers"] = {
    Name = "Purple_Classy_Sneakers",
    Price = 50,
    Icon = nil, --"Purple_Classy_Sneakers"
    ForSale = true,
}
items["Tailor_Slippers"] = {
    Name = "Tailor_Slippers",
    Price = 50,
    Icon = nil, --"Tailor_Slippers"
    ForSale = false,
}
items["White_Purple_Sneakers"] = {
    Name = "White_Purple_Sneakers",
    Price = 50,
    Icon = nil, --"White_Purple_Sneakers"
    ForSale = true,
}
items["Bright_Pink_Sneakers"] = {
    Name = "Bright_Pink_Sneakers",
    Price = 50,
    Icon = nil, --"Bright_Pink_Sneakers"
    ForSale = true,
}

ShoesConstants.AssetsPath = "Shoes"
ShoesConstants.TabOrder = 3
ShoesConstants.TabIcon = Images.Icons.Shoe
ShoesConstants.SortOrder = Enum.SortOrder.LayoutOrder
ShoesConstants.MaxEquippables = 1
ShoesConstants.CanUnequip = true
ShoesConstants.Items = items

return ShoesConstants
