local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local ShirtConstants = {}
export type Item = {
    Name: string,
    Price: number,
    Icon: string,
    ForSale: boolean,
}

local items: { [string]: Item } = {}
items["Purple_Shirt"] = {
    Name = "Purple_Shirt",
    Price = 0,
    Icon = Images.Shirts["Purple_Shirt"],
    ForSale = true,
}
items["Flannel_Shirt"] = {
    Name = "Flannel_Shirt",
    Price = 0,
    Icon = Images.Shirts["Flannel_Shirt"],
    ForSale = false,
}
items["Heart_Bomber_Jacket"] = {
    Name = "Heart_Bomber_Jacket",
    Price = 0,
    Icon = nil, --"Heart_Bomber_Jacket"
    ForSale = true,
}
items["Classic_Pink_Sweater"] = {
    Name = "Classic_Pink_Sweater",
    Price = 0,
    Icon = nil, --"Classic_Pink_Sweater"
    ForSale = true,
}
items["Classic_Teal_Sweater"] = {
    Name = "Classic_Teal_Sweater",
    Price = 0,
    Icon = nil, --"Classic_Teal_Sweater"
    ForSale = true,
}
items["Brazil_Jersey"] = {
    Name = "Brazil_Jersey",
    Price = 0,
    Icon = nil, --"Brazil_Jersey"
    ForSale = true,
}
items["Ice_Cream_Scooper_Shirt"] = {
    Name = "Ice_Cream_Scooper_Shirt",
    Price = 0,
    Icon = nil, --"Ice_Cream_Scooper_Shirt"
    ForSale = true,
}
items["Waiter_Shirt"] = {
    Name = "Waiter_Shirt",
    Price = 0,
    Icon = nil, --"Waiter_Shirt"
    ForSale = true,
}
items["Blue_Snooker_Shirt"] = {
    Name = "Blue_Snooker_Shirt",
    Price = 0,
    Icon = nil, --"Blue_Snooker_Shirt"
    ForSale = true,
}
items["Dark_Red_Snooker_Shirt"] = {
    Name = "Dark_Red_Snooker_Shirt",
    Price = 0,
    Icon = nil, --"Dark_Red_Snooker_Shirt"
    ForSale = true,
}
items["Teal_Snooker_Shirt"] = {
    Name = "Teal_Snooker_Shirt",
    Price = 0,
    Icon = nil, --"Teal_Snooker_Shirt"
    ForSale = true,
}
items["Orange_Snooker_Shirt"] = {
    Name = "Orange_Snooker_Shirt",
    Price = 0,
    Icon = nil, --"Orange_Snooker_Shirt"
    ForSale = true,
}
items["Purple_Snooker_Shirt"] = {
    Name = "Purple_Snooker_Shirt",
    Price = 0,
    Icon = nil, --"Purple_Snooker_Shirt"
    ForSale = true,
}
items["Red_Snooker_Shirt"] = {
    Name = "Red_Snooker_Shirt",
    Price = 0,
    Icon = nil, --"Red_Snooker_Shirt"
    ForSale = true,
}
items["Gray_Snooker_Shirt"] = {
    Name = "Gray_Snooker_Shirt",
    Price = 0,
    Icon = nil, --"Gray_Snooker_Shirt"
    ForSale = true,
}
items["Blue_Pentagon_Shirt"] = {
    Name = "Blue_Pentagon_Shirt",
    Price = 0,
    Icon = nil, --"Blue_Pentagon_Shirt"
    ForSale = true,
}
items["Green_Pentagon_Shirt"] = {
    Name = "Green_Pentagon_Shirt",
    Price = 0,
    Icon = nil, --"Green_Pentagon_Shirt"
    ForSale = true,
}
items["Orange_Gradient_Shirt"] = {
    Name = "Orange_Gradient_Shirt",
    Price = 0,
    Icon = nil, --"Orange_Gradient_Shirt"
    ForSale = true,
}
items["Green_Gradient_Shirt"] = {
    Name = "Green_Gradient_Shirt",
    Price = 0,
    Icon = nil, --"Green_Gradient_Shirt"
    ForSale = true,
}
items["Blue_Gradient_Shirt"] = {
    Name = "Blue_Gradient_Shirt",
    Price = 0,
    Icon = nil, --"Blue_Gradient_Shirt"
    ForSale = true,
}
items["Pink_Gradient_Shirt"] = {
    Name = "Pink_Gradient_Shirt",
    Price = 0,
    Icon = nil, --"Pink_Gradient_Shirt"
    ForSale = true,
}
items["Purple_Starry_Shirt"] = {
    Name = "Purple_Starry_Shirt",
    Price = 0,
    Icon = nil, --"Purple_Starry_Shirt"
    ForSale = true,
}
items["Red_Starry_Shirt"] = {
    Name = "Red_Starry_Shirt",
    Price = 0,
    Icon = nil, --"Red_Starry_Shirt"
    ForSale = true,
}
items["Green_Starry_Shirt"] = {
    Name = "Green_Starry_Shirt",
    Price = 0,
    Icon = nil, --"Green_Starry_Shirt"
    ForSale = true,
}
items["Blue_Eskimo_Jacket"] = {
    Name = "Blue_Eskimo_Jacket",
    Price = 0,
    Icon = nil, --"Blue_Eskimo_Jacket"
    ForSale = true,
}
items["Yellow_Eskimo_Jacket"] = {
    Name = "Yellow_Eskimo_Jacket",
    Price = 0,
    Icon = nil, --"Yellow_Eskimo_Jacket"
    ForSale = true,
}
items["Pink_Eskimo_Jacket"] = {
    Name = "Pink_Eskimo_Jacket",
    Price = 0,
    Icon = nil, --"Pink_Eskimo_Jacket"
    ForSale = true,
}
items["Burgundy_Eskimo_Jacket"] = {
    Name = "Burgundy_Eskimo_Jacket",
    Price = 0,
    Icon = nil, --"Burgundy_Eskimo_Jacket"
    ForSale = true,
}
items["Green_Eskimo_Jacket"] = {
    Name = "Green_Eskimo_Jacket",
    Price = 0,
    Icon = nil, --"Green_Eskimo_Jacket"
    ForSale = true,
}
items["Black_Star_Studded_Shirt"] = {
    Name = "Black_Star_Studded_Shirt",
    Price = 0,
    Icon = nil, --"Black_Star_Studded_Shirt"
    ForSale = true,
}
items["Blue_Diver_Tank"] = {
    Name = "Blue_Diver_Tank",
    Price = 0,
    Icon = nil, --"Blue_Diver_Tank"
    ForSale = true,
}
items["Pink_Diver_Tank"] = {
    Name = "Pink_Diver_Tank",
    Price = 0,
    Icon = nil, --"Pink_Diver_Tank"
    ForSale = true,
}
items["Pink_Dotted_Shirt"] = {
    Name = "Pink_Dotted_Shirt",
    Price = 0,
    Icon = nil, --"Pink_Dotted_Shirt"
    ForSale = true,
}
items["Black_Checkered_Shirt"] = {
    Name = "Black_Checkered_Shirt",
    Price = 0,
    Icon = nil, --"Black_Checkered_Shirt"
    ForSale = true,
}
items["Cocoa_Dotted_Shirt"] = {
    Name = "Cocoa_Dotted_Shirt",
    Price = 0,
    Icon = nil, --"Cocoa_Dotted_Shirt"
    ForSale = true,
}
items["Purple_Dotted_Shirt"] = {
    Name = "Purple_Dotted_Shirt",
    Price = 0,
    Icon = nil, --"Purple_Dotted_Shirt"
    ForSale = true,
}
items["Red_Dotted_Shirt"] = {
    Name = "Red_Dotted_Shirt",
    Price = 0,
    Icon = nil, --"Red_Dotted_Shirt"
    ForSale = true,
}
items["White_Checkered_Shirt"] = {
    Name = "White_Checkered_Shirt",
    Price = 0,
    Icon = nil, --"White_Checkered_Shirt"
    ForSale = true,
}
items["Yellow_Checkered_Shirt"] = {
    Name = "Yellow_Checkered_Shirt",
    Price = 0,
    Icon = nil, --"Yellow_Checkered_Shirt"
    ForSale = true,
}
items["Yellow_Diver_Tank"] = {
    Name = "Yellow_Diver_Tank",
    Price = 0,
    Icon = nil, --"Yellow_Diver_Tank"
    ForSale = true,
}
items["Red_Star_Studded_Shirt"] = {
    Name = "Red_Star_Studded_Shirt",
    Price = 0,
    Icon = nil, --"Red_Star_Studded_Shirt"
    ForSale = true,
}
items["Red_And_Yellow_Starry_Shirt"] = {
    Name = "Red_And_Yellow_Starry_Shirt",
    Price = 0,
    Icon = nil, --"Red_And_Yellow_Starry_Shirt"
    ForSale = true,
}
items["Red_Checkered_Shirt"] = {
    Name = "Red_Checkered_Shirt",
    Price = 0,
    Icon = nil, --"Red_Checkered_Shirt"
    ForSale = true,
}
items["Teal_Checkered_Shirt"] = {
    Name = "Teal_Checkered_Shirt",
    Price = 0,
    Icon = nil, --"Teal_Checkered_Shirt"
    ForSale = true,
}
items["Pink_Spotted_Shirt"] = {
    Name = "Pink_Spotted_Shirt",
    Price = 0,
    Icon = nil, --"Pink_Spotted_Shirt"
    ForSale = true,
}
items["Green_Spotted_Shirt"] = {
    Name = "Green_Spotted_Shirt",
    Price = 0,
    Icon = nil, --"Green_Spotted_Shirt"
    ForSale = true,
}
items["Red_Sweater"] = {
    Name = "Red_Sweater",
    Price = 0,
    Icon = nil, --"Red_Sweater"
    ForSale = true,
}
items["Pink_Parisan_Blouse"] = {
    Name = "Pink_Parisan_Blouse",
    Price = 0,
    Icon = nil, --"Pink_Parisan_Blouse"
    ForSale = true,
}
items["Teal_Starry_Shirt"] = {
    Name = "Teal_Starry_Shirt",
    Price = 0,
    Icon = nil, --"Teal_Starry_Shirt"
    ForSale = true,
}
items["Pink_Starry_Shirt"] = {
    Name = "Pink_Starry_Shirt",
    Price = 0,
    Icon = nil, --"Pink_Starry_Shirt"
    ForSale = true,
}
items["Yellow_Blouse"] = {
    Name = "Yellow_Blouse",
    Price = 0,
    Icon = nil, --"Yellow_Blouse"
    ForSale = true,
}
items["White_Plaid_Shirt"] = {
    Name = "White_Plaid_Shirt",
    Price = 0,
    Icon = nil, --"White_Plaid_Shirt"
    ForSale = true,
}
items["Red_Plaid_Shirt"] = {
    Name = "Red_Plaid_Shirt",
    Price = 0,
    Icon = nil, --"Red_Plaid_Shirt"
    ForSale = true,
}
items["Green_Plaid_Shirt"] = {
    Name = "Green_Plaid_Shirt",
    Price = 0,
    Icon = nil, --"Green_Plaid_Shirt"
    ForSale = true,
}
items["Purple_Plaid_Shirt"] = {
    Name = "Purple_Plaid_Shirt",
    Price = 0,
    Icon = nil, --"Purple_Plaid_Shirt"
    ForSale = true,
}
items["Pink_Plaid_Shirt"] = {
    Name = "Pink_Plaid_Shirt",
    Price = 0,
    Icon = nil, --"Pink_Plaid_Shirt"
    ForSale = true,
}
items["Purple_Gradient_Shirt"] = {
    Name = "Purple_Gradient_Shirt",
    Price = 0,
    Icon = nil, --"Purple_Gradient_Shirt"
    ForSale = true,
}
items["Teal_Pentagon_Shirt"] = {
    Name = "Teal_Pentagon_Shirt",
    Price = 0,
    Icon = nil, --"Teal_Pentagon_Shirt"
    ForSale = true,
}
items["Pink_Pentagon_Shirt"] = {
    Name = "Pink_Pentagon_Shirt",
    Price = 0,
    Icon = nil, --"Pink_Pentagon_Shirt"
    ForSale = true,
}
items["Red_Pentagon_Shirt"] = {
    Name = "Red_Pentagon_Shirt",
    Price = 0,
    Icon = nil, --"Red_Pentagon_Shirt"
    ForSale = true,
}
items["Yellow_Snooker_Shirt"] = {
    Name = "Yellow_Snooker_Shirt",
    Price = 0,
    Icon = nil, --"Yellow_Snooker_Shirt"
    ForSale = true,
}
items["Rocket_Sweater"] = {
    Name = "Rocket_Sweater",
    Price = 0,
    Icon = nil, --"Rocket_Sweater"
    ForSale = true,
}
items["Peach_Parisan_Blouse"] = {
    Name = "Peach_Parisan_Blouse",
    Price = 0,
    Icon = nil, --"Peach_Parisan_Blouse"
    ForSale = true,
}
items["Stripped_Yellow_Tee"] = {
    Name = "Stripped_Yellow_Tee",
    Price = 0,
    Icon = nil, --"Stripped_Yellow_Tee"
    ForSale = true,
}
items["Pizza_Chefs_Jacket"] = {
    Name = "Pizza_Chefs_Jacket",
    Price = 0,
    Icon = nil, --"Pizza_Chefs_Jacket"
    ForSale = true,
}
items["Purple_Classy_Suit"] = {
    Name = "Purple_Classy_Suit",
    Price = 0,
    Icon = nil, --"Purple_Classy_Suit"
    ForSale = true,
}
items["Sailor_Shirt"] = {
    Name = "Sailor_Shirt",
    Price = 0,
    Icon = nil, --"Sailor_Shirt"
    ForSale = true,
}
items["Tailor_Suit"] = {
    Name = "Tailor_Suit",
    Price = 0,
    Icon = nil, --"Tailor_Suit"
    ForSale = true,
}
items["Student_Shirt"] = {
    Name = "Student_Shirt",
    Price = 0,
    Icon = nil, --"Student_Shirt"
    ForSale = true,
}
items["Red_Lined_Tee"] = {
    Name = "Red_Lined_Tee",
    Price = 0,
    Icon = nil, --"Red_Lined_Tee"
    ForSale = true,
}
items["Red_Rain_Jacket"] = {
    Name = "Red_Rain_Jacket",
    Price = 0,
    Icon = nil, --"Red_Rain_Jacket"
    ForSale = true,
}

ShirtConstants.AssetsPath = "Shirts"
ShirtConstants.TabOrder = 1
ShirtConstants.TabIcon = Images.Icons.Shirt
ShirtConstants.SortOrder = Enum.SortOrder.LayoutOrder
ShirtConstants.MaxEquippables = 1
ShirtConstants.CanUnequip = true
ShirtConstants.Items = items

return ShirtConstants
