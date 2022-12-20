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
items["Backwards_Cap"] = {
    Name = "Backwards_Cap",
    Price = 0,
    Icon = Images.Hats["Backwards_Cap"],
    ForSale = true,
}
items["Bird_Hat"] = {
    Name = "Bird_Hat",
    Price = 0,
    Icon = Images.Hats["Bird_Hat"],
    ForSale = true,
}
items["Boot_Hat"] = {
    Name = "Boot_Hat",
    Price = 0,
    Icon = Images.Hats["Boot_Hat"],
    ForSale = true,
}
items["Detectives_Hat"] = {
    Name = "Detectives_Hat",
    Price = 1000,
    Icon = Images.Hats["Detectives_Hat"],
    ForSale = true,
}
items["100k_Glasses"] = {
    Name = "100k_Glasses",
    Price = 100,
    Icon = Images.Hats["100k_Glasses"],
    ForSale = true,
}
items["Thug_Life_Glasses"] = {
    Name = "Thug_Life_Glasses",
    Price = 0,
    Icon = Images.Hats["Thug_Life_Glasses"],
    ForSale = true,
}
items["Umbrella"] = {
    Name = "Umbrella",
    Price = 0,
    Icon = Images.Hats["Umbrella"],
    ForSale = true,
}
items["Witch_Hat"] = {
    Name = "Witch_Hat",
    Price = 0,
    Icon = Images.Hats["Witch_Hat"],
    ForSale = true,
}
items["Wizard_Hat"] = {
    Name = "Wizard_Hat",
    Price = 0,
    Icon = Images.Hats["Wizard_Hat"],
    ForSale = true,
}
items["Green_Headphones"] = {
    Name = "Green_Headphones",
    Price = 0,
    Icon = Images.Hats["Green_Headphones"],
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
