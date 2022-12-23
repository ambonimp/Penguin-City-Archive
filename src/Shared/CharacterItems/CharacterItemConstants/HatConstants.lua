local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local HatConstants = {}
export type Item = {
    Name: string,
    Price: number,
    Icon: string,
    ForSale: boolean,
}

local items: { [string]: Item } = {}
items["Fancy_Top_Hat"] = {
    Name = "Fancy_Top_Hat",
    Price = 100,
    Icon = nil, --"Fancy_Top_Hat"
    ForSale = false,
}
items["Clear_Glasses"] = {
    Name = "Clear_Glasses",
    Price = 45,
    Icon = nil, --"Clear_Glasses"
    ForSale = true,
}
items["Pizza_Chef_Hat"] = {
    Name = "Pizza_Chef_Hat",
    Price = 25,
    Icon = nil, --"Pizza_Chef_Hat"
    ForSale = false,
}
items["Ice_Cream_Hat"] = {
    Name = "Ice_Cream_Hat",
    Price = 25,
    Icon = nil, --"Ice_Cream_Hat"
    ForSale = false,
}
items["Blue_Snorkels"] = {
    Name = "Blue_Snorkels",
    Price = 50,
    Icon = nil, --"Blue_Snorkels"
    ForSale = true,
}
items["Pink_Snorkels"] = {
    Name = "Pink_Snorkels",
    Price = 50,
    Icon = nil, --"Pink_Snorkels"
    ForSale = true,
}
items["Yellow_Snorkels"] = {
    Name = "Yellow_Snorkels",
    Price = 50,
    Icon = nil, --"Yellow_Snorkels"
    ForSale = true,
}
items["Bamboo_Straw_Hat"] = {
    Name = "Bamboo_Straw_Hat",
    Price = 45,
    Icon = nil, --"Bamboo_Straw_Hat"
    ForSale = true,
}
items["Sailor_Cap"] = {
    Name = "Sailor_Cap",
    Price = 60,
    Icon = nil, --"Sailor_Cap"
    ForSale = false,
}
items["Peach_Bucket_Hat"] = {
    Name = "Peach_Bucket_Hat",
    Price = 35,
    Icon = nil, --"Peach_Bucket_Hat"
    ForSale = false,
}
items["Pop_Cap"] = {
    Name = "Pop_Cap",
    Price = 60,
    Icon = nil, --"Pop_Cap"
    ForSale = false,
}
items["Urban_Cap"] = {
    Name = "Urban_Cap",
    Price = 60,
    Icon = nil, --"Urban_Cap"
    ForSale = true,
}
items["Pink_Bucket_Hat"] = {
    Name = "Pink_Bucket_Hat",
    Price = 55,
    Icon = nil, --"Pink_Bucket_Hat"
    ForSale = true,
}
items["Student_Cap"] = {
    Name = "Student_Cap",
    Price = 0,
    Icon = nil, --"Student_Cap"
    ForSale = false,
}
items["Farmer_Hat"] = {
    Name = "Farmer_Hat",
    Price = 65,
    Icon = nil, --"Farmer_Hat"
    ForSale = true,
}
items["Adventurer_Hat"] = {
    Name = "Adventurer_Hat",
    Price = 25,
    Icon = nil, --"Adventurer_Hat"
    ForSale = true,
}
items["Backwards_Cap"] = {
    Name = "Backwards_Cap",
    Price = 35,
    Icon = nil, --"Backwards_Cap"
    ForSale = true,
}
items["Bath_Hat"] = {
    Name = "Bath_Hat",
    Price = 75,
    Icon = nil, --"Bath_Hat"
    ForSale = true,
}
items["Bear_Hat"] = {
    Name = "Bear_Hat",
    Price = 50,
    Icon = nil, --"Bear_Hat"
    ForSale = true,
}
items["Bee_Hat"] = {
    Name = "Bee_Hat",
    Price = 50,
    Icon = nil, --"Bee_Hat"
    ForSale = true,
}
items["Beret"] = {
    Name = "Beret",
    Price = 65,
    Icon = nil, --"Beret"
    ForSale = true,
}
items["Biker_Helmet"] = {
    Name = "Biker_Helmet",
    Price = 150,
    Icon = nil, --"Biker_Helmet"
    ForSale = true,
}
items["Bird_Hat"] = {
    Name = "Bird_Hat",
    Price = 85,
    Icon = nil, --"Bird_Hat"
    ForSale = true,
}
items["Boot_Hat"] = {
    Name = "Boot_Hat",
    Price = 100,
    Icon = nil, --"Boot_Hat"
    ForSale = true,
}
items["Bottle_Hat"] = {
    Name = "Bottle_Hat",
    Price = 60,
    Icon = nil, --"Bottle_Hat"
    ForSale = true,
}
items["Bowl_Hat"] = {
    Name = "Bowl_Hat",
    Price = 45,
    Icon = nil, --"Bowl_Hat"
    ForSale = true,
}
items["Bucket_Hat"] = {
    Name = "Bucket_Hat",
    Price = 70,
    Icon = nil, --"Bucket_Hat"
    ForSale = true,
}
items["Bunny_Ears"] = {
    Name = "Bunny_Ears",
    Price = 100,
    Icon = nil, --"Bunny_Ears"
    ForSale = true,
}
items["Cap"] = {
    Name = "Cap",
    Price = 15,
    Icon = nil, --"Cap"
    ForSale = true,
}
items["Cat_Ears"] = {
    Name = "Cat_Ears",
    Price = 50,
    Icon = nil, --"Cat_Ears"
    ForSale = true,
}
items["Chef_Hat"] = {
    Name = "Chef_Hat",
    Price = 75,
    Icon = nil, --"Chef_Hat"
    ForSale = true,
}
items["Chicken_Hat"] = {
    Name = "Chicken_Hat",
    Price = 150,
    Icon = nil, --"Chicken_Hat"
    ForSale = true,
}
items["Clown_Hair"] = {
    Name = "Clown_Hair",
    Price = 150,
    Icon = nil, --"Clown_Hair"
    ForSale = true,
}
items["Conical_Straw_Hat"] = {
    Name = "Conical_Straw_Hat",
    Price = 60,
    Icon = nil, --"Conical_Straw_Hat"
    ForSale = true,
}
items["Cowboy"] = {
    Name = "Cowboy",
    Price = 100,
    Icon = nil, --"Cowboy"
    ForSale = true,
}
items["Crown"] = {
    Name = "Crown",
    Price = 450,
    Icon = nil, --"Crown"
    ForSale = true,
}
items["Detective_Hat"] = {
    Name = "Detective_Hat",
    Price = 65,
    Icon = nil, --"Detective_Hat"
    ForSale = true,
}
items["Drinking_Hat"] = {
    Name = "Drinking_Hat",
    Price = 120,
    Icon = nil, --"Drinking_Hat"
    ForSale = true,
}
items["Easter_Basket"] = {
    Name = "Easter_Basket",
    Price = 120,
    Icon = nil, --"Easter_Basket"
    ForSale = true,
}
items["Feather_Hat"] = {
    Name = "Feather_Hat",
    Price = 35,
    Icon = nil, --"Feather_Hat"
    ForSale = true,
}
items["Firefighter_Hat"] = {
    Name = "Firefighter_Hat",
    Price = 75,
    Icon = nil, --"Firefighter_Hat"
    ForSale = true,
}
items["Fisher_Hat"] = {
    Name = "Fisher_Hat",
    Price = 85,
    Icon = nil, --"Fisher_Hat"
    ForSale = true,
}
items["Flower_Crown"] = {
    Name = "Flower_Crown",
    Price = 45,
    Icon = nil, --"Flower_Crown"
    ForSale = true,
}
items["Flower_Pot"] = {
    Name = "Flower_Pot",
    Price = 15,
    Icon = nil, --"Flower_Pot"
    ForSale = true,
}
items["Football_Helmet"] = {
    Name = "Football_Helmet",
    Price = 35,
    Icon = nil, --"Football_Helmet"
    ForSale = true,
}
items["Frog_Bucket_Hat"] = {
    Name = "Frog_Bucket_Hat",
    Price = 55,
    Icon = nil, --"Frog_Bucket_Hat"
    ForSale = true,
}
items["Gardening_Hat"] = {
    Name = "Gardening_Hat",
    Price = 85,
    Icon = nil, --"Gardening_Hat"
    ForSale = true,
}
items["Gentleman_Top_Hat"] = {
    Name = "Gentleman_Top_Hat",
    Price = 100,
    Icon = nil, --"Gentleman_Top_Hat"
    ForSale = true,
}
items["Giant_Bow"] = {
    Name = "Giant_Bow",
    Price = 0,
    Icon = nil, --"Giant_Bow"
    ForSale = true,
}
items["Graduation_Hat"] = {
    Name = "Graduation_Hat",
    Price = 85,
    Icon = nil, --"Graduation_Hat"
    ForSale = true,
}
items["Hair_Headband"] = {
    Name = "Hair_Headband",
    Price = 15,
    Icon = nil, --"Hair_Headband"
    ForSale = true,
}
items["Hard_Hat"] = {
    Name = "Hard_Hat",
    Price = 50,
    Icon = nil, --"Hard_Hat"
    ForSale = true,
}
items["Headphones"] = {
    Name = "Headphones",
    Price = 75,
    Icon = nil, --"Headphones"
    ForSale = true,
}
items["Hockey_Helmet"] = {
    Name = "Hockey_Helmet",
    Price = 60,
    Icon = nil, --"Hockey_Helmet"
    ForSale = true,
}
items["Jellyfish_Hat"] = {
    Name = "Jellyfish_Hat",
    Price = 115,
    Icon = nil, --"Jellyfish_Hat"
    ForSale = true,
}
items["Joker_Hat"] = {
    Name = "Joker_Hat",
    Price = 100,
    Icon = nil, --"Joker_Hat"
    ForSale = true,
}
items["Knight_Helmet"] = {
    Name = "Knight_Helmet",
    Price = 100,
    Icon = nil, --"Knight_Helmet"
    ForSale = true,
}
items["Lucky_Hat"] = {
    Name = "Lucky_Hat",
    Price = 85,
    Icon = nil, --"Lucky_Hat"
    ForSale = true,
}
items["Miner_Hat"] = {
    Name = "Miner_Hat",
    Price = 65,
    Icon = nil, --"Miner_Hat"
    ForSale = true,
}
items["Mouse_Ears"] = {
    Name = "Mouse_Ears",
    Price = 55,
    Icon = nil, --"Mouse_Ears"
    ForSale = true,
}
items["Mushroom_Hat"] = {
    Name = "Mushroom_Hat",
    Price = 150,
    Icon = nil, --"Mushroom_Hat"
    ForSale = true,
}
items["Nurse_Hat"] = {
    Name = "Nurse_Hat",
    Price = 45,
    Icon = nil, --"Nurse_Hat"
    ForSale = true,
}
items["Pink_Bunny_Ears"] = {
    Name = "Pink_Bunny_Ears",
    Price = 0,
    Icon = nil, --"Pink_Bunny_Ears"
    ForSale = true,
}
items["Pink_Sunhat"] = {
    Name = "Pink_Sunhat",
    Price = 50,
    Icon = nil, --"Pink_Sunhat"
    ForSale = true,
}
items["Pirate_Bandana"] = {
    Name = "Pirate_Bandana",
    Price = 35,
    Icon = nil, --"Pirate_Bandana"
    ForSale = true,
}
items["Pirate_Captain_Hat"] = {
    Name = "Pirate_Captain_Hat",
    Price = 75,
    Icon = nil, --"Pirate_Captain_Hat"
    ForSale = true,
}
items["Pirate_Hat"] = {
    Name = "Pirate_Hat",
    Price = 35,
    Icon = nil, --"Pirate_Hat"
    ForSale = true,
}
items["Police_Cap"] = {
    Name = "Police_Cap",
    Price = 55,
    Icon = nil, --"Police_Cap"
    ForSale = true,
}
items["Popcorn_Hat"] = {
    Name = "Popcorn_Hat",
    Price = 85,
    Icon = nil, --"Popcorn_Hat"
    ForSale = true,
}
items["Pot"] = {
    Name = "Pot",
    Price = 0,
    Icon = nil, --"Pot"
    ForSale = true,
}
items["Propeller_Hat"] = {
    Name = "Propeller_Hat",
    Price = 0,
    Icon = nil, --"Propeller_Hat"
    ForSale = true,
}
items["Robin_Hood"] = {
    Name = "Robin_Hood",
    Price = 55,
    Icon = nil, --"Robin_Hood"
    ForSale = true,
}
items["Santa_Hat"] = {
    Name = "Santa_Hat",
    Price = 85,
    Icon = nil, --"Santa_Hat"
    ForSale = true,
}
items["Seaweed_Hat"] = {
    Name = "Seaweed_Hat",
    Price = 125,
    Icon = nil, --"Seaweed_Hat"
    ForSale = true,
}
items["Shark_Hat"] = {
    Name = "Shark_Hat",
    Price = 225,
    Icon = nil, --"Shark_Hat"
    ForSale = true,
}
items["Soldier_Helmet"] = {
    Name = "Soldier_Helmet",
    Price = 65,
    Icon = nil, --"Soldier_Helmet"
    ForSale = true,
}
items["Sombrero"] = {
    Name = "Sombrero",
    Price = 150,
    Icon = nil, --"Sombrero"
    ForSale = true,
}
items["Spiky_Top_Hat"] = {
    Name = "Spiky_Top_Hat",
    Price = 250,
    Icon = nil, --"Spiky_Top_Hat"
    ForSale = true,
}
items["Steampunk_Hat"] = {
    Name = "Steampunk_Hat",
    Price = 300,
    Icon = nil, --"Steampunk_Hat"
    ForSale = true,
}
items["Straw_Hat"] = {
    Name = "Straw_Hat",
    Price = 0,
    Icon = nil, --"Straw_Hat"
    ForSale = true,
}
items["Thug_Life_Glasses"] = {
    Name = "Thug_Life_Glasses",
    Price = 100,
    Icon = nil, --"Thug_Life_Glasses"
    ForSale = true,
}
items["Traffic_Cone"] = {
    Name = "Traffic_Cone",
    Price = 100,
    Icon = nil, --"Traffic_Cone"
    ForSale = true,
}
items["Umbrella"] = {
    Name = "Umbrella",
    Price = 45,
    Icon = nil, --"Umbrella"
    ForSale = true,
}
items["Valentine_Day"] = {
    Name = "Valentine_Day",
    Price = 25,
    Icon = nil, --"Valentine_Day"
    ForSale = true,
}
items["Viking_Helmet"] = {
    Name = "Viking_Helmet",
    Price = 150,
    Icon = nil, --"Viking_Helmet"
    ForSale = true,
}
items["Witch_Hat"] = {
    Name = "Witch_Hat",
    Price = 200,
    Icon = nil, --"Witch_Hat"
    ForSale = true,
}
items["Wizard_Hat"] = {
    Name = "Wizard_Hat",
    Price = 150,
    Icon = nil, --"Wizard_Hat"
    ForSale = true,
}

HatConstants.AssetsPath = "Hats"
HatConstants.TabOrder = 5
HatConstants.TabIcon = Images.Icons.Hat
HatConstants.SortOrder = Enum.SortOrder.Name
HatConstants.MaxEquippables = 3
HatConstants.CanUnequip = true
HatConstants.Items = items

return HatConstants
