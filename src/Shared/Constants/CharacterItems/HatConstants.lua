local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local HatConstants = {}
export type Item = {
    Name: string,
    Price: number,
    Icon: string,
}

local items: { [string]: Item } = {}
items["Backwards_Cap"] = {
    Name = "Backwards_Cap",
    Price = 0,
    Icon = Images.Hats["Backwards_Cap"],
}
items["Bird_Hat"] = {
    Name = "Bird Hat",
    Price = 0,
    Icon = Images.Hats["Bird_Hat"],
}
items["Boot_Hat"] = {
    Name = "Boot_Hat",
    Price = 0,
    Icon = Images.Hats["Boot_Hat"],
}
items["Detectives_Hat"] = {
    Name = "Detective's_Hat",
    Price = 0,
    Icon = Images.Hats["Detective's_Hat"],
}
items["100k_Glasses"] = {
    Name = "100k_Glasses",
    Price = 0,
    Icon = Images.Hats["100k_Glasses"],
}
items["Thug_Life_Glasses"] = {
    Name = "Thug_Life_Glasses",
    Price = 0,
    Icon = Images.Hats["Thug_Life_Glasses"],
}
items["Umbrella"] = {
    Name = "Umbrella",
    Price = 0,
    Icon = Images.Hats["Umbrella"],
}
items["Witch_Hat"] = {
    Name = "Witch_Hat",
    Price = 0,
    Icon = Images.Hats["Witch_Hat"],
}
items["Wizard_Hat"] = {
    Name = "Wizard_Hat",
    Price = 0,
    Icon = Images.Hats["Wizard_Hat"],
}
items["Green_Headphones"] = {
    Name = "Green_Headphones",
    Price = 0,
    Icon = Images.Hats["Green_Headphones"],
}

HatConstants.InventoryPath = "Hats"
HatConstants.TabOrder = 5
HatConstants.TabIcon = Images.Icons.Hat
HatConstants.SortOrder = Enum.SortOrder.Name
HatConstants.MaxEquippables = 3
HatConstants.CanUnequip = true
HatConstants.Items = items

return HatConstants
