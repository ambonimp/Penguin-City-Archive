local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images.Images)

local HatConstants = {}
export type Item = {
    Price: number,
    Icon: string,
}

HatConstants.InventoryPath = "Hats"
HatConstants.TabOrder = 1
HatConstants.TabIcon = Images.Icons.Hat
HatConstants.SortOrder = Enum.SortOrder.Name
HatConstants.MaxEquippables = 4
HatConstants.CanUnequip = true
HatConstants.Items = {
    ["Backwards_Cap"] = {
        Price = 0,
        Icon = Images.Hats["Backwards_Cap"],
    } :: Item,
    ["Bird_Hat"] = {
        Price = 0,
        Icon = Images.Hats["Bird_Hat"],
    } :: Item,
    ["Boot_Hat"] = {
        Price = 0,
        Icon = Images.Hats["Boot_Hat"],
    } :: Item,
    ["Detective's_Hat"] = {
        Price = 0,
        Icon = Images.Hats["Detective's_Hat"],
    } :: Item,
    ["100k_Glasses"] = {
        Price = 0,
        Icon = Images.Hats["100k_Glasses"],
    } :: Item,
    ["Thug_Life_Glasses"] = {
        Price = 0,
        Icon = Images.Hats["Thug_Life_Glasses"],
    } :: Item,
    ["Umbrella"] = {
        Price = 0,
        Icon = Images.Hats["Umbrella"],
    } :: Item,
    ["Witch_Hat"] = {
        Price = 0,
        Icon = Images.Hats["Witch_Hat"],
    } :: Item,
    ["Wizard_Hat"] = {
        Price = 0,
        Icon = Images.Hats["Wizard_Hat"],
    } :: Item,
    ["Green_Headphones"] = {
        Price = 0,
        Icon = Images.Hats["Green_Headphones"],
    } :: Item,
}

return HatConstants
